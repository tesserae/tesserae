#! /usr/bin/perl

#
# bigram-freq.pl 
#
# the purpose of this script is to create a table of bigram 
# frequencies using the data from index_multi

=head1 NAME

bigram-freq.pl	- calculate word bigram frequencies

=head1 SYNOPSIS

bigram-freq.pl [options]

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang LANG>

Process all texts for language LANG.

=item B<--quiet>

Don't print messages to STDERR.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is bigram-freq.pl.

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

use CGI qw(:standard);
use POSIX;
use Storable qw(nstore retrieve);

# allow unicode output

binmode STDOUT, ":utf8";

# set language

my $lang = 'la';

# print help message

my $help = 0;

# don't print progress info to STDERR

my $quiet = 0;

#
# command-line options
#

GetOptions(
	"lang=s"          => \$lang,
	"quiet"           => \$quiet,
	"help"            => \$help
	);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# get the list of texts to index

my @corpus = @{get_textlist($lang)};

#
# examine each file
#

for my $unit (qw/phrase/) {

	# one frequency table for the whole corpus
	
	my %count_corpus;
	my $total_corpus;

	my $pr = ProgressBar->new($#corpus+1, $quiet);

	for my $text (@corpus) {
	
		$pr->advance();
	
		my %count_text;
		my $total_text;
			
		my $file_index_stem = catfile($fs{data}, 'v3', $lang, $text, $text . ".multi_${unit}_stem");
		
		my %index = %{retrieve($file_index_stem)};
		
		while (my ($key, $value) = each %index) {
		
			my $count = scalar(keys %{$index{$key}});
		
			$count_text{$key}   =  $count;
			$total_text         += $count;

			$count_corpus{$key} += $count;
		}
		
		$total_corpus += $total_text;
		
		for (values %count_text) { $_ /= $total_text }
		
		my $file_freq = catfile($fs{data}, 'v3', $lang, $text, $text . ".freq_bigram_${unit}_stem");
		
		nstore \%count_text, $file_freq;
	}

	for (values %count_corpus) { $_ /= $total_corpus }
	
	my $file_freq = catfile($fs{data}, 'common', "$lang.freq_bigram_${unit}_stem");
	
	nstore \%count_corpus, $file_freq;
}

#
# subroutines
#

sub get_textlist {
	
	my $lang = shift;

	my $directory = catdir($fs{data}, 'v3', $lang);

	opendir(DH, $directory);
	
	my @textlist = grep {/^[^.]/ && ! /\.part\./} readdir(DH);
	
	closedir(DH);
		
	return \@textlist;
}
