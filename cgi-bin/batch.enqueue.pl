#!/usr/bin/env perl

=head1 NAME

batch.enqueue.pl - CGI wrapper for batch.prepare.pl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

batch.prepare.pl
batch.run.pl

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.enqueue.pl.

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
use File::Temp;
use File::Path qw/mkpath rmtree/;
use CGI qw/:standard/;

#
# initialize variables
#

my $dir_client = catdir($fs{tmp},  'batch');
my $dir_manage = catdir($fs{data}, 'batch');

my @params = qw/
	source
	target
	unit
	feature
	stop
	stbasis
	dist
	dibasis
	cutoff/;

my %par;

#
# initialize CGI
#

my $query = CGI->new() || die "$!";

# print html header

print header('-charset'=>'utf-8', '-type'=>'text/html');

#
# get user options
#

for (@params) {

	@{$par{$_}} = $query->param($_);
}

#
# open database
#

my $dbh = init_db();

#
# create the config file for batch.prepare.pl
#

my $session = generate_config_file(\%par);

#
# add config file to the queue
#

enqueue($dbh, $session);

#
# redirect to status page
#

print html_redirect($session);

#
# subroutines
#

#
# open connection to database
#

sub init_db {
	
	# make sure working directory exists and create it if not
	
	unless (-d $dir_client) {
	
		mkpath($dir_client) or die "can't create $dir_client: $!";
	}
	
	# connect to database

	my $file_db = catfile($dir_client, 'queue.db');
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file_db", "", "");
	
	# check to make sure table exists
	
	my $sth = $dbh->prepare(
		'select name from sqlite_master where type="table";'
	);
	
	$sth->execute;
	
	my $exists = 0;

	while (my $table = $sth->fetchrow_arrayref) {
		
		if ($table->[0] eq 'queue') {
		
			$exists = 1;
		}
	}
		
	# create it if it doesn't
	
	unless ($exists) {
		
		my $sth = $dbh->prepare(
			'create table queue (
				SESSION char(4),
				KILL int
			);'
		);
		
		$sth->execute;
	}
	
	# return database handle
	
	return $dbh;
}

#
# add a batch session to the queue
#

sub enqueue {

	my ($dbh, $session) = @_;

	my $sth = $dbh->prepare(
		"insert into queue values ('$session', 0);"
	);
	
	$sth->execute;
}

#
# create a config file for batch.preprare.pl
#

sub generate_config_file {

	my $par = shift;
	my %par = %$par;
	
	my $fh = File::Temp->new(
		DIR      => $dir_client, 
		TEMPLATE => 'conf.XXXX',
		UNLINK   => 0
	);

	binmode $fh, ':utf8';
	
	for my $p (@params) {
	
		print $fh "[$p]\n";
		
		for my $val (@{$par{$p}}) {
		
			print $fh "$val\n";
		}
		
		print $fh "\n";
	}
	
	close ($fh);
	
	chmod 0644, $fh->filename;
	
	my $session = $fh->filename;
	
	$session = substr($session, -4, 4);
	
	return $session;
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
		<!-- <meta http-equiv="Refresh" content="15: url='$redirect'"> -->
		<link rel="stylesheet" type="text/css" href="$url{css}/style.css" />
		</style>
	</head>
	<body>
		<h2>Your run has been queued</h2>
		
		<p>
			Your search has been entered into a queue to be processed. It has been assigned the session ID <strong>$session</strong>. You can check the status and estimated time to completion of your search, download results when finished, or cancel processing at any time by pointing your browser to the URL below.
		</p>
		
		<p>
			<a href="$redirect">$redirect</a>
		</p>
	</body>
</html>
END_HTML

	return $html;
}