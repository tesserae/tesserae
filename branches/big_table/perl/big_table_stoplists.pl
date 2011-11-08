#
# big_table_stoplists.pls
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words.

use Storable;

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

	print STDERR "writing data/$lang/stop_word\n";

	open (FH, ">", "data/$lang/stop_word") || die "can't write to data/$lang/stop_word: $!";

	for ( sort { $count{$b} <=> $count{$a} } keys %count )
	{
		print FH "$count{$_}\t$_\n";
	}

	close FH;

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

	print STDERR "writing data/$lang/stop_stem\n";

	open (FH, ">", "data/$lang/stop_stem") || die "can't write to data/$lang/stop_stem: $!";

	for (sort { $stem_count{$b} <=> $stem_count{$a} } keys %stem_count )
	{
		print FH "$stem_count{$_}\t$_\n";
	}

	close FH;

	print STDERR "\n";
}
