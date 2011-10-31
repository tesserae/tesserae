use Storable;

binmode STDOUT, ":utf8";

my %lewis = %{ retrieve('lewis.cache') };

my %count;
my %index;

for my $key (sort keys %lewis)
{

	for my $def ( @{ $lewis{$key} } )
	{
		$count{$def}++;
		push @{ $index{$def} }, $key;
	}
}

for my $def ( sort { $count{$b} <=> $count{$a} } grep { $count{$_} > 15 } keys %count )
{
	print "$count{$def}\t$def\n";
}
