#! /usr/bin/perl

#
# print a frequency list
#

=head1 NAME

print-stoplist.pl - print a frequency list

=head1 SYNOPSIS

perl print-stoplist.pl [--score] [--feature FEATURE] TEXT
perl print-stoplist.pl [--feature FEATURE] --corpus LANG

=head1 DESCRIPTION

Prints the feature frequency table used to create stoplists, either for a particular
text or for the corpus of texts for a given language.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<TEXT>

The name of a text for which to produce the frequency table.  The name should be given
as for read_table.pl.

=item B<--score>

Print the frequencies used for scoring instead of those used for stoplists.

=item B<--feature FEATURE>

Print the frequencies for feature FEATURE.  Default is I<stem>.

=item B<--corpus LANG>

Print the corpus-wide frequencies for language LANG.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

read_table.pl - perform a Tesserae search

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is print-stoplist.pl.

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

use CGI qw/:standard/;
use Storable qw(nstore retrieve);
use File::Path qw(mkpath rmtree);

# initialize some variables

my $help    = 0;
my $corpus  = 0;
my $file    = '';
my $mode    = 'stop';
my $score   = 0;
my $feature = 'stem';

# get user options

GetOptions( 'corpus=s'  => \$corpus,
			'score'     => \$score,   
			'feature=s' => \$feature,
			'help'      => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

$mode = 'score' if ($score and not $corpus);

$file = shift @ARGV;

if ($corpus) {

	$file = catfile($fs{data}, 'common', "$corpus.$feature.freq");
}
else {

	my $file_lang = catfile($fs{data}, 'common', 'lang');
	my %lang = %{retrieve($file_lang)};

	$file = catfile($fs{data}, 'v3', $lang{$file}, $file, "$file.freq_${mode}_$feature");
	
	unless (-s $file) {
	
		print STDERR "can't read frequency list $file: $!\n";

		pod2usage(1);
	}
}

my %freq = %{retrieve($file)};

for my $key (sort {$freq{$b} <=> $freq{$a}} keys %freq) {

	print sprintf("%.8f\t%s\n", $freq{$key}, $key);
}
