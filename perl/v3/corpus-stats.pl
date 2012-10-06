#
# corpus-stats.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use File::Spec::Functions;
use Storable qw(nstore retrieve);

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV) {

	if (/^[a-zA-Z]{1,4}$/)	{ 
	
		next unless -d catdir($fs_data, 'v3', $_);
		push @lang, $_;
	}
}

#
# main loop
#

# word counts come from documents already parsed.
# stem counts are based on word counts, but also 
# use the cached stem dictionary
#

for my $lang(@lang) {

	my $file_stem_cache = catfile($fs_data, 'common', $lang . '.stem.cache');
	my $file_syn_cache  = catfile($fs_data, 'common', $lang . '.syn.cache');

	my %file_freq = (
	
		word  => catfile($fs_data, 'common', $lang . '.word.freq'),
		stem  => catfile($fs_data, 'common', $lang . '.stem.freq'),
		syn   => catfile($fs_data, 'common', $lang . '.syn.freq'),
	);
	
	# get a list of all the word counts

	my @texts;
	
	my $dir = catdir($fs_data, 'v3', $lang);

	opendir (DH, $dir);

	push @texts, (grep {!/\.part\./ && !/^\./} readdir DH);

	closedir (DH);

	#
	# combine the counts for each file to get a corpus count
	#

	my %total;
	my %count;

	for my $text (@texts) {
	
		print STDERR "checking $text:";
		
		for my $feature (qw/word stem syn/) {
		
			my $file_index = catfile($fs_data, 'v3', $lang, $text, "$text.index_$feature");

			next unless -s $file_index;

			my %index = %{retrieve($file_index)};

			print STDERR " $feature";

			for (keys %index) { 
			
				$count{$feature}{$_} += scalar(@{$index{$_}});
				$total{$feature}     += scalar(@{$index{$_}});
			}
		}
		
		print STDERR "\n";
	}

	# after the whole corpus is tallied,	
	# convert counts to frequencies and save
	
	for my $feature (qw/word stem syn/) {
	
		next unless defined $count{$feature};
		
		for (values %{$count{$feature}}) {
		
			$_ /= $total{$feature};
		}

		print STDERR "writing $file_freq{$feature}\n";
	
		nstore $count{$feature}, $file_freq{$feature};
	}
}