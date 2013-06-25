#!/usr/bin/env perl

=head1 NAME

batch.manage.pl - manage the batch job queue

=head1 SYNOPSIS

batch.manage.pl [options]

Meant to be run periodically by cron.

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.manage.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use DBI;
use Parallel::ForkManager;

# initialize some variables

my $dir_client = catdir($fs{tmp},  'batch');
my $dir_manage = catdir($fs{data}, 'batch');

my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

#
# fork child daemons
#

my $pm = Parallel::ForkManager->new(4);

for (my $i = 0; 1; $i = ($i + 1) % 5) {

	sleep 5;

	$pm->start and next;

	# connect to databases

	my ($dbh_manage, $dbh_client) = init_db();

	# get the next queued session

	my $session = get_next($dbh_manage, $dbh_client);
	
	# run the session

	if (defined $session) {

		run_session($session);
	}
		
	$pm->finish;
}

$pm->wait_all_children;

#
# subroutines
#

#
# connect to databases
#

sub init_db {

	# check for client db;
	# don't create it if it doesn't exist
	
	my $db_client  = catfile($dir_client, 'queue.db');
	
	my $dbh_client;

	if ( -e $db_client) {
	
		$dbh_client = DBI->connect("dbi:SQLite:dbname=$db_client", "", "");
	}

	# check for manager db, create if doesn't exist

	my $db_manage  = catfile($dir_manage, 'queue.db');
	my $dbh_manage = DBI->connect("dbi:SQLite:dbname=$db_manage", "", "");

	# make sure table exists
	
	my $exists = $dbh_manage->selectrow_arrayref(
		
		'select name from sqlite_master where type="table" and name="queue";'
	);
	
	# create it if it doesn't
	
	unless ($exists) {
		
		my $sth = $dbh_manage->prepare(
			'create table queue (
				SESSION char(4),
				START   int,
				TIME    int,
				NRUNS   int,
				RUNID   int,
				STATUS  int
			);'
		);
		
		$sth->execute;
	}

	return ($dbh_manage, $dbh_client);
}

#
# check the queue
#

sub get_next {
	
	my ($dbh_manage, $dbh_client) = @_;

	unless ($dbh_client) { return undef }

	my $session;

	# get the list of queued config files
	
	my @queue;

	my $queue = $dbh_client->selectall_arrayref(
		"select SESSION from queue order by ROWID;"
	);
		
	if (defined $queue) {
	
		@queue = map { $_->[0] } @$queue;
	}
	
	# get the list of past and ongoing jobs
	
	my %status;
		
	my $status = $dbh_manage->selectall_arrayref(
		"select SESSION, STATUS from queue;"
	);
		
	if (defined $status) {
	
		for my $row (@$status) {
		
			$status{$row->[0]} = $row->[1];
		}
	}
			
	# go down the list of queued configs
	# and pop the first one that hasn't
	# yet been run
		
	while ($session = shift @queue) {
		
		if (defined $status{$session}) {
			
		}
		else {
			
			last;
		}
	}
	continue {
		
		$session = undef;
	}
	
	#
	# make sure there aren't too many searches going already
	#
	
	my $max_ongoing = 5;
	my $ongoing = 0;
	
	for (keys %status) {
		
		if (defined $status{$_} and $status{$_} == 0)  { $ongoing++ }
	}
	
	if ($ongoing >= $max_ongoing) {
		
		$session = undef;
	}
		
	return $session;
}

#
# start session
#

sub run_session {
	
	my $session = shift;
	
	my $file_config = catfile($fs{tmp}, 'batch', 'conf.' . $session);
	
	my $file_script = catfile($fs{script}, 'batch', 'batch.run.pl');
	
	my $cmd = join(" ",
		$file_script,
		'--quiet',
		'--manage',
		'--plugin'  => 'Tallies',
		'--session' => 'batch.' . $session,
		'--parent'  => $dir_manage,
		$file_config
	);
	
	`$cmd`;
}