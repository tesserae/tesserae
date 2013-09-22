#!/usr/bin/env perl

=head1 NAME

niko_partition.pl - partition huge dataset produced by Nikolaev plugin

=head1 SYNOPSIS

niko_partition.pl --table TABLE --key KEY [--table TABLE2 --key KEY2] SESSION

=head1 DESCRIPTION

Splits I<intertexts.txt> and I<tokens.txt> into a number of smaller files
for easier processing.

=head1 OPTIONS AND ARGUMENTS

=over

item B<--table> TABLE

Table to partition

item B<--key> KEY

Column by which to sort as an integer; first column is 0.

item B<SESSION>

Directory containing the tables.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is niko_partition.pl.

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

use Encode qw/encode decode/;
use File::Path qw/mkpath rmtree/;

# initialize some variables

my $help  = 0;
my $quiet = 0;
my @table = ();
my @key   = (); 

# get user options

GetOptions(
	'table=s' => \@table,
	'key=i'   => \@key,
	'quiet'   => \$quiet,
	'help'    => \$help
);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

#
# session is mandatory arg
#

my $session = shift(@ARGV);

unless (defined $session and -d $session) {

	warn "must specify session to read";
	pod2usage(1);
}

#
# each table needs a key
#

if ($#table != $#key) {

	warn "number of tables must equal number of keys";
	pod2usage(1);
}

#
# partition intertexts, tokens
#

my $partitions = catdir($session, 'parts');
mkpath($partitions) unless -d $partitions;

for my $i (0..$#table) {

	partition($table[$i], $key[$i]);
}

		
#
# subroutines
#

# divide intertexts, tokens into batches based on run id

sub partition {
	
	my ($name, $key) = @_;

	my $file_in = catfile($session, $name . '.txt');
	
	open (my $fhi, '<:utf8', $file_in) or die "can't read $file_in: $!";
	
	print STDERR "partitioning $file_in\n" unless $quiet;
	
	my $pr = VerySlowProgressBar->new(-s $file_in, $quiet);
	
	$pr->advance(length(decode('utf8', <$fhi>)));
			
	my @fho;
	
	while (my $line = <$fhi>) {
	
		$pr->advance(length(decode('utf8', $line)));
			
		my @field = split(/\t/, $line);
		
		my $subscript = int($field[$key] / 1000);
		
		unless (defined $fho[$subscript]) {
		
			my $file_out = catfile($partitions, $name . '.' . $subscript . '.txt');

			open (my $fh, '>:utf8', $file_out) or die "can't write $file_out: $!";

			$fho[$subscript] = *$fh;
		}
		
		my $fho = $fho[$subscript];
		print $fho $line;
	}
	
	for (my $i = 0; $i <= $#fho; $i++) {
	
		close $fho[$i];
	}
	
	print "table $name: last part $#fho\n";
}
