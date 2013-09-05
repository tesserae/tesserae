#!/usr/bin/env perl

=head1 NAME

build-trans-cache.pl - install translation dictionary

=head1 SYNOPSIS

build-trans-cache.pl [--feature NAME] DICT

=head1 DESCRIPTION

Reads a translation dictionary in CSV format; creates and installs Tesserae dictionary in Storable binary format. Dictionaries should be utf-8 encoded text, with one line per headword. Each line begins with the Greek headword to be translated, followed by one or more Latin headwords to be considered "translations" of the Greek. Fields must be separated by commas.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<DICT>

Dictionary file to read.

=item B<--feature> NAME

Optional name for feature set. Default is "trans".

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is build-trans-cache.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall, James Gawley

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

use Storable qw/nstore/;
use Encode;
use File::Copy;
use Unicode::Normalize;
use utf8;

# initialize some variables

my $feat  = 'trans';
my $help  = 0;
my $quiet = 0;

my $re_dia   = qr/[\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]/;
my $re_vowel = qr/[αειηουωΑΕΙΗΟΥΩ]/;

# get user options

GetOptions(
	'feature=s' => \$feat,
	'help'      => \$help,
	'quiet'     => \$quiet
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# Get filename from user arg

my $file = shift @ARGV;

unless ($file) {
	
	warn "Please specify CSV dictionary to read.";
	pod2usage(1);
}

binmode STDOUT, ':utf8';

#


# parse the csv dictionary
#

my %trans;

open (my $fh, '<:utf8', $file) or die "Can't read dictionary $file: $!";

print STDERR "Parsing $file\n" unless $quiet;

my $pr = ProgressBar->new(-s $file, $quiet);

while (my $line = <$fh>) {

	$pr->advance(length(Encode::encode('utf8', $line)));

	chomp $line;
	
	my ($head, @trans) = split(/\s*,\s*/, $line);
	
	$head = NFKD($head);
	$head =~ s/\d//g;
	$head =~ s/^(${re_dia}+)(${re_vowel}{2,})/$2/;
	$head =~ s/^(${re_dia}+)(${re_vowel}{1})/$2$1/;
	$head =~ s/σ\b/ς/;
	
	@trans = grep { /\S/ } @trans;
	
	next unless @trans;
	
	push @{$trans{$head}}, @trans;
	
	print "$head: " . join(" ", @trans) . "\n";
}

#
# save as Storable binary
#

my $file_cache = catfile($fs{data}, 'common', "grc.$feat.cache");

print STDERR "Writing $file_cache\n" unless $quiet;

nstore(\%trans, $file_cache);

#
# copy the Latin stem dictionary
#

my $from = catfile($fs{data}, 'common', 'la.stem.cache');
my $to   = catfile($fs{data}, 'common', "la.$feat.cache");

unless (-s $from) {

	my $warning = <<END;
Can't find Latin stem cache $from!
Without Latin stems the translation feature will not work!
Please run build-stem-cache.pl, then either re-run this script
or copy $from to $to yourself.
END

	warn $warning;
	die "No stem dictionary, can't continue.";
}

print STDERR "Writing $to\n" unless $quiet;

copy($from, $to);



