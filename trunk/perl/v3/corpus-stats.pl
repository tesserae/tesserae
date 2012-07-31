#
# corpus-stats.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

use strict;
use warnings;

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use File::Spec::Functions;
use Storable qw(nstore retrieve);

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV) {

	if (/gr/)	{ push @lang, "grc" }
	if (/la/)	{ push @lang, "la"	}
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
	
	my $file_freq_word  = catfile($fs_data, 'common', $lang . '.word.freq');
	my $file_freq_stem  = catfile($fs_data, 'common', $lang . '.stem.freq');
	my $file_freq_syn   = catfile($fs_data, 'common', $lang . '.syn.freq');
	
	# get a list of all the word counts

	my @texts;
	
	my $dir = catdir($fs_data, 'v3', $lang);

	opendir (DH, $dir);

	push @texts, (grep {!/\.part\./ && !/^\./} readdir DH);

	closedir (DH);

	#
	# combine the counts for each file to get a corpus count
	#

	my %count_word;
	my %freq_word;

	for my $text (@texts) {
	
		print STDERR "reading $text\n";
		
		# get just the short name from the file
		
		$text =~ /.*\/(.+)/;
		my $text_key = $1;

		# retrieve the count
		
		my $file_index_word = catfile($fs_data, 'v3', $lang, $text, $text.'.index_word');
		
		my %index = %{retrieve($file_index_word)};

		for (keys %index) { 
			
			$count_word{$_} += scalar(@{$index{$_}});
		}
	}
	
	# convert to frequencies

	my $total = 0;
	for (keys %count_word) { $total += $count_word{$_} }
	for (keys %count_word) { $freq_word{$_} = $count_word{$_}/$total }

	# save
	
	print STDERR "writing $file_freq_word\n";
	
	nstore \%freq_word, $file_freq_word;	
	
	print STDERR "\n";
	
	#
	# stem counts
	#

	print STDERR "reading $file_stem_cache\n";

	my %stem_cache = %{retrieve($file_stem_cache)};

	print STDERR "calculating stem counts\n";

	my %count_stem;
	my %freq_stem;
	
	for my $word (keys %count_word) {
	
		if ( defined $stem_cache{$word} ) {
		
			for my $stem ( @{$stem_cache{$word}} ) {
			
				$count_stem{$stem} += $count_word{$word};
			}
		}
		else {

			$count_stem{$word} += $count_word{$word};
		}
	}
	
	# convert to frequencies
	
	$total = 0;

	for (keys %count_stem) { $total += $count_stem{$_} }
	for (keys %count_stem) { $freq_stem{$_} = $count_stem{$_}/$total }
	
	# save

	print STDERR "writing $file_freq_stem\n";
	
	nstore \%freq_stem, $file_freq_stem;
		
	print STDERR "\n";
	
	#
	# semantic counts
	#

	print STDERR "reading $file_syn_cache\n";
	
	my %syn_cache = %{retrieve($file_syn_cache)};
	
	print STDERR "calculating syn counts\n";
	
	my %count_syn;
	my %freq_syn;
	
	for my $word (keys %count_word) {
		
		my %uniq_syn;
		
		# if the form has stems, base syns on them
		
		if ( defined $stem_cache{$word} ) {
		
			for my $stem ( @{$stem_cache{$word}} ) {
			
				# check each stem for syns
				
				if ( defined $syn_cache{$stem} ) {
					
					for my $syn ( @{$syn_cache{$stem}} ) {
						
						$uniq_syn{$syn} = 1;
					}
				}
				
				# add the stem itself
				
				$uniq_syn{$stem} = 1;
			}
		}
		
		# if it has no stems, base syns on form itself
		
		else {
			
			# check the form for syns
			
			if ( defined $syn_cache{$word} ) {
			
				for my $syn ( @{$syn_cache{$word}} ) {
					
					$uniq_syn{$syn} = 1;
				}
			}
			
			# add the form itself
			
			$uniq_syn{$word} = 1;
		}
		
		# remove duplicates in counting
		
		for (keys %uniq_syn) {
		
			$count_syn{$_} += $count_word{$word};
		}
	}
	
	# convert to frequencies
	
	$total = 0;
	
	for (keys %count_syn) { $total += $count_syn{$_} }
	for (keys %count_syn) { $freq_syn{$_} = $count_syn{$_}/$total }
	
	# save
	
	print STDERR "writing $file_freq_syn\n";
	
	nstore \%freq_syn, $file_freq_syn;
		
	print STDERR "\n";
	
}
