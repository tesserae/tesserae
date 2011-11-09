#
# big_table_frequencies.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

use Storable qw(nstore retrieve);

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV)
{
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

for my $lang(@lang)
{

	my $file_stem_cache = "data/$lang/$lang.stem.cache";

	# get a list of all the word counts

	my @count_files;

	opendir (DH, "data/$lang/word");

	push @count_files, (grep {/\.count$/ && !/\.part\./ && -f} map { "data/$lang/word/$_" } readdir DH);

	closedir (DH);

	#
	# combine the counts for each file to get a corpus count
	#

	my %count;

	for (@count_files)
	{
	
		print STDERR "reading $_\n";

		my %count_this_file = %{ retrieve($_) };

		for (keys %count_this_file)
		{
			$count{$_} += $count_this_file{$_};
		}
	}

	print STDERR "writing data/$lang/$lang.word_count\n";

	nstore \%count, "data/$lang/$lang.word_count";

	#
	# stem counts
	#

	print STDERR "reading $file_stem_cache\n";

	my %cache = %{retrieve($file_stem_cache)};

	print STDERR "calculating stem counts\n";

	my %stem_count;

	for my $word (keys %count)
	{
		if ( defined $cache{$word} )
		{
			for my $stem ( @{$cache{$word}} )
			{
				$stem_count{$stem} += $count{$word};
			}
		}
	}

	print STDERR "writing data/$lang/$lang.stem_count\n";

	nstore \%stem_count, "data/$lang/$lang.stem_count";

	print STDERR "\n";
}
