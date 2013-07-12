#!/usr/bin/env perl

=head1 NAME

batch.kill.pl - client script for cancelling/removing batch run from queue

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

batch.enqueue.pl
batch.run.pl

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.kill.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

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
use CGI qw/:standard/;

#
# initialize variables
#

my $dir_client = catdir($fs{tmp},  'batch');
my $dir_manage = catdir($fs{data}, 'batch');

#
# initialize CGI
#

my $query = CGI->new() || die "$!";

# print html header

print header('-charset'=>'utf-8', '-type'=>'text/html');

my $session = $query->param('session');
my $dequeue = $query->param('dequeue');

#
# open database
#

my ($dbh_manage, $dbh_client) = init_db();

#
# set kill flag
#

if (get_status($session)) {
	
	set_kill($session);
}

#
# under special circumstances, remove from queue altogether
#

if ($dequeue) { 

	dequeue($session);
}

print html_redirect($session);


#
# subroutines
#

#
# open connection to database
#

sub init_db {
	
	my $db_client  = catfile($dir_client, 'queue.db');
	my $db_manage  = catfile($dir_manage, 'queue.db');

	unless (-e $db_client) {
		
		die "batch.kill failed: client queue doesn't exist";
	}
	unless (-e $db_manage) {
	
		die "batch.kill failed: manager queue doesn't exist";
	}
	
	my $dbh_client = DBI->connect("dbi:SQLite:dbname=$db_client", "", "");
	my $dbh_manage = DBI->connect("dbi:SQLite:dbname=$db_manage", "", "");

	return ($dbh_manage, $dbh_client);
}

#
# remove a batch session from the queue
#

sub dequeue {

	my $session = shift;

	my $success = $dbh_client->do(
		"delete from queue where SESSION='$session';"
	);
	
	return $success;
}

#
# set kill switch
#

sub set_kill {

	my $session = shift;

	my $success = $dbh_client->do(
		"update queue set KILL=1 where SESSION='$session';"
	);
		
	return $success;
}

#
# check session status
#

sub get_status {

	my $session = shift;

	#
	# get status from session management files
	#
	
	# does the session have an entry in the client queue?
		
	my $stat_client = $dbh_client->selectrow_arrayref(
		
		"select * from queue where SESSION='$session';"
	);
	
	#
	# check status in manager db
	#
		
	my $stat_manage = $dbh_manage->selectrow_arrayref(

		"select STATUS from queue where SESSION='$session';"
	);
	
	if (defined $stat_manage) {
	
		$stat_manage = $stat_manage->[0];
	}

	#
	# to be developed
	#
	
	my $flag = defined $stat_client ? 1 : 0;
	
	return $flag;
}


#
# produce html redirecting to the status script
#

sub html_redirect {

	my $session = shift;

	my $redirect = "$url{cgi}/batch.status.pl?session=$session";
	
	my $html = <<END_HTML;
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
	<head>
		<title>Tesserae Batch Run Summary</title>
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin" />
		<meta http-equiv="refresh" content="0; url='$redirect'">
		<link rel="stylesheet" type="text/css" href="$url{css}/style.css" />
		</style>
	</head>
	<body>
		<h2>Attempting to cancel session $session</h2>
		
		<p>
			If you are not redirected automatically, <a href="$redirect">click here</a> to confirm that the session has been cancelled.
		</p>
	</body>
</html>
END_HTML

	return $html;
}