use Storable;

my $file_word_count = "../semantics/corpus_count";
my $file_stem_cache = "../semantics/archimedes.cache";

print STDERR "reading $file_word_count\n";

my %count = %{retrieve($file_word_count)};

print STDERR "calculating word counts\n";

open FH, ">stop_word";

for ( sort { $count{$b} <=> $count{$a} } keys %count )
{
	print FH "$count{$_}\t$_\n";
}

close FH;

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

open FH, ">stop_stem";

for (sort { $stem_count{$b} <=> $stem_count{$a} } keys %stem_count )
{
	print FH "$stem_count{$_}\t$_\n";
}

close FH;
