#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# bigram-freq.pl 
#
# the purpose of this script is to create a table of bigram 
# frequencies using the data from index_multi

use strict;
use warnings;

use CGI qw(:standard);

use Getopt::Long;
use POSIX;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

# allow unicode output

binmode STDOUT, ":utf8";

# set language

my $lang = 'la';

# don't print progress info to STDERR

my $quiet = 0;

#
# command-line options
#

GetOptions(
	"lang=s"          => \$lang,
	"quiet"           => \$quiet
	);

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
			
		my $file_index_stem = catfile($fs_data, 'v3', $lang, $text, $text . ".multi_${unit}_stem");
		
		my %index = %{retrieve($file_index_stem)};
		
		while (my ($key, $value) = each %index) {
		
			my $count = scalar(keys %{$index{$key}});
		
			$count_text{$key}   =  $count;
			$total_text         += $count;

			$count_corpus{$key} += $count;
		}
		
		$total_corpus += $total_text;
		
		for (values %count_text) { $_ /= $total_text }
		
		my $file_freq = catfile($fs_data, 'v3', $lang, $text, $text . ".freq_bigram_${unit}_stem");
		
		nstore \%count_text, $file_freq;
	}

	for (values %count_corpus) { $_ /= $total_corpus }
	
	my $file_freq = catfile($fs_data, 'common', "$lang.freq_bigram_${unit}_stem");
	
	nstore \%count_corpus, $file_freq;
}

#
# subroutines
#

sub get_textlist {
	
	my $lang = shift;

	my $directory = catdir($fs_data, 'v3', $lang);

	opendir(DH, $directory);
	
	my @textlist = grep {/^[^.]/ && ! /\.part\./} readdir(DH);
	
	closedir(DH);
		
	return \@textlist;
}
