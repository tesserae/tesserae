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

use utf8;

# initialize some variables

my $help = 0;

my %convert = (
	Α => 1,
	Β => 2,
	Γ => 3,
	Δ => 4,
	Ε => 5,
	Ζ => 6,
	Η => 7,
	Θ => 8,
	Ι => 9,
	Κ => 10,
	Λ => 11,
	Μ => 12,
	Ν => 13,
	Ξ => 14,
	Ο => 15,
	Π => 16,
	Ρ => 17,
	Σ => 18,
	Τ => 19,
	Υ => 20,
	Φ => 21,
	Χ => 22,
	Ψ => 23,
	Ω => 24,
	
	A => 1,
	B => 2,
	D => 4,
	E => 5,
	Z => 6,
	H => 7,
	I => 9,
	K => 10,
	M => 12,
	N => 13,
	O => 15,
	P => 17,
	T => 19,
	Y => 20,
	X => 22
);
	

# get user options

GetOptions(
	'help'  => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

#
#
#

binmode STDOUT, ":utf8";

my $file = shift @ARGV;

open (my $fh, "<:utf8", $file) or die "Can't open $file: $!";

# copy header

my $head = <$fh>;
print $head;

# now pass each remaining line through the converter

while (my $line = <$fh>) {

	my @field = split(/\t/, $line);
	
	if ( defined $convert{$field[3]} ) {

		$field[3] = $convert{$field[3]};
	}
	elsif ( int($field[3]) eq $field[3] ) {
	
	}
	else {
		
		print STDERR "! convert($field[3]) undefined \n";
	}
	
	@field = map { $_ or "" } @field;
	
	print join("\t", @field);
}

