use Storable;

my $lang="grc";

my $file_stem_cache = "data/$lang/$lang.stem.cache";

# get a list of all the word counts

my @count_files;

opendir (DH, "data/$lang/word");

push @count_files, (grep {/\.count$/ && -f} map { "data/$lang/word/$_" } readdir DH);

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

print STDERR "calculating word counts\n";

open FH, ">stop_word";

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

open FH, ">stop_stem";

for (sort { $stem_count{$b} <=> $stem_count{$a} } keys %stem_count )
{
	print FH "$stem_count{$_}\t$_\n";
}

close FH;
