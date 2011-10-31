use Storable qw(nstore retrieve);

binmode STDOUT, ":utf8";

my %lewis = %{ retrieve('lewis.cache') };

my $entries;


# invert the cache, so that defs are keys and headwords are values

my %index;

for my $key (sort keys %lewis)
{

	for my $def ( @{ $lewis{$key} } )
	{

		push @{ $index{$def} }, $key;

		$entries++;
	}
}

print STDERR scalar(keys %lewis) . " headwords, $entries definitions\n\n";


# erase the original cache

%lewis = ();
$entries = 0;

# read the custom list of defs to be deleted

open FH, 'to_be_removed.txt';

while (<FH>)
{
	chomp;

	if (/\d+\t(.+)/)
	{
		my $def = $1;

		delete $index{$def};
		print STDERR "deleting $def\n";
	}
}

close FH;


# also delete any remaining defs that are a single, abbreviated word

for ( grep { /^\w+\.$/ && length($_) <= 4 } keys %index )
{
	delete $index{$_};
	print STDERR "deleting $_\n";
}


# reconstitute the cache from the pruned, inverted one
# 
# make the keys all lowercase

for my $def ( keys %index )
{
	
	for my $key ( @{ $index{$def} } )
	{

		push @{ $lewis{lc($key)} }, $def;

		$entries++;
	}
}

# store the new, pruned cache

print STDERR scalar(keys %lewis) . " headwords, $entries definitions\n";

nstore \%lewis, 'lewis.cache';
