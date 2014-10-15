#!/usr/bin/env perl

#
# This is a template for how Tesserae scripts should begin.
#
# Please fill in documentation notes in POD below.
#
# Don't forget to modify the COPYRIGHT section as follows:
#  - name of the script where it says "The Original Code is"
#  - your name(s) where it says "Contributors"
#

=head1 NAME

name.pl	- do something

=head1 SYNOPSIS

name.pl [options] ARG1 [, ARG2, ...]

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<ARG1>

Description of what ARG1 does.

=item B<--option>

Description of what --option does.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is name.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s):

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
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use CGI qw/:standard/;
use Storable;
use utf8;
use DBI;
use Encode;

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# initialize some variables

my $sep  = "\t";
my $help = 0;

#
# check for cgi interface
#

my $cgi = CGI->new() || die "$!";

my $no_cgi = defined($cgi->request_method()) ? 0 : 1;

#
# get user options
#

if ($no_cgi) {
	
	GetOptions(
		'sep=s' => \$sep,
		'help'  => \$help
	);

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}
}
else {
	
	print header('-charset'=>'utf-8', '-type'=>'text/plain');
	
	$sep = $cgi->param('sep') || $sep;
}

my $dbh = init_db();
print_table();

#
# subroutines
#

#
# connect to database
#

sub init_db {

	# connect to database

	my $file_db = catfile($fs{tmp}, 'syn-diagnostic.db');
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file_db", "", "");

	# check to make sure table exists
	
	my $sth = $dbh->prepare(
		'select name from sqlite_master where type="table";'
	);
	
	$sth->execute;
	
	my $exists = 0;

	while (my $table = $sth->fetchrow_arrayref) {
		
		if ($table->[0] eq 'results') {
		
			$exists = 1;
		}
	}
		
	# create it if it doesn't
	
	unless ($exists) {

		die "table results doesn't exist!";
	}

	return $dbh;
}

#
# see which words already have entries
#

sub print_table {
	
	my $aref = $dbh->selectall_arrayref('select * from results;');
	
	print join($sep, qw/
		greek
		freq
		pos
		trans_1a
		trans_1b
		trans_2a
		trans_2b
		trans_3a
		trans_3b
		valid_1a
		valid_1b
		pos_1a
		pos_1b
		valid_2a
		valid_2b
		pos_2a
		pos_2b
		valid_3a
		valid_3b
		pos_3a
		pos_3b
		valid_4a
		valid_4b
		pos_4a
		pos_4b
		auth/
	);
	
	print "\n";
	
	for my $row (@$aref) {

		my @row = @$row;
		$row[0] = decode('utf8', $row[0]);
		print join($sep, @row) . "\n";
	}
}
