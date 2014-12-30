#!/usr/bin/env perl

=head1 NAME

build-trans-cache.pl - install translation dictionary

=head1 SYNOPSIS

build-trans-cache.pl [--feature NAME] --la|grc DICT [--la|grc DICT]

=head1 DESCRIPTION

Reads one or more translation/synonymy dictionaries in CSV format; creates and installs Tesserae feature dictionaries in Storable binary format. Dictionaries should be utf-8 encoded text, with one line per headword. Each line begins with the headword to be translated, followed by one or more  headwords to be considered its "translations" or "synonyms." Fields must be separated by commas. See I<perldoc build-trans-cache.pl> for examples.

=head1 EXAMPLES

To create a Greek-Latin translation feature set, first use I<sims-export.py> to create a dictionary with Greek headwords in the first position on the line, followed by Latin translations. Then do, e.g.,

  I<build-trans-cache.pl> --feature g2l --grc g2l_dict.csv

This will create a feature set called "g2l," using the dictionary "g2l_dict.csv" for the Greek feature set and the base stem dictionary for the Latin.

On the other hand, to create a synonymy feature set, first use I<sims-export.py> to create a dictionary without the translation filter, so that Greek and Latin headwords are used indiscriminately throughout the CSV dictionary. Then give I<build-trans-cache> the same CSV file for both Greek and Latin, e.g.,

   I<build-trans-cache.pl> --feature syn --grc syn_dict.csv --la syn_dict.csv

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--la|grc> DICT

Language-based dictionary to read. Use B<--la> to specify a Latin dictionary, B<--grc> to specify a Greek dictionary. If a dictionary is provided for one language only, the other will use the existing stem dictionary.

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

use Storable qw/nstore/;
use Encode;
use File::Copy;
use Unicode::Normalize;
use utf8;

# initialize some variables

my $feat  = 'trans';
my $help  = 0;
my $quiet = 0;
my %file;


# get user options

GetOptions(
	'feature=s'   => \$feat,
	'latin=s'     => \$file{la},
	'grc|greek=s' => \$file{grc},
	'help'        => \$help,
	'quiet'       => \$quiet
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

binmode STDOUT, ':utf8';

#
# parse the csv dictionary
#
for my $lang (qw/grc la/) {

	my %trans;

	if (defined $file{$lang}) {
		
		open (my $fh, '<:utf8', $file{$lang}) or die "Can't read dictionary $file{$lang}: $!";

		print STDERR "Parsing $file{$lang}\n" unless $quiet;

		my $pr = ProgressBar->new(-s $file{$lang}, $quiet);

		while (my $line = <$fh>) {

			$pr->advance(length(Encode::encode('utf8', $line)));

			chomp $line;
	
			my ($head, @trans) = split(/\s*,\s*/, $line);
	
			$head = Tesserae::standardize($lang, $head);
			
			@trans = Tesserae::standardize($lang, @trans);
			
			@trans = grep { /\S/ } @trans;
	
			next unless @trans;
	
			push @{$trans{$head}}, @trans;
		}

		#
		# save as Storable binary
		#

		my $file_cache = catfile($fs{data}, 'common', "$lang.$feat.cache");

		print STDERR "Writing $file_cache\n" unless $quiet;

		nstore(\%trans, $file_cache);
	}
	else {
		
		#
		# copy the base stem dictionary
		#

		my $from = catfile($fs{data}, 'common', "$lang.stem.cache");
		my $to   = catfile($fs{data}, 'common', "$lang.$feat.cache");

		unless (-s $from) {

			my $warning = "Can't find base stem cache $from!\n"
							. "Without stems the translation feature will not work!\n"
							. "Please run build-stem-cache.pl, then either re-run this script\n"
							. "or copy $from to $to yourself.\n";

			warn $warning;
			die "No stem dictionary, can't continue.";
		}
		
		print STDERR "Writing $to\n" unless $quiet;

		copy($from, $to);
	}
}

