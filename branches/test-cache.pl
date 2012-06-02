use strict;
use warnings;

use Storable qw(retrieve);

my %cache = %{ retrieve("stem.cache") };

# here's the lewis & short cache

my %lewis = %{ retrieve("lewis.cache") };

print scalar(keys %lewis) . " keys in lewis\n";

my %uniq;

my %count;

my @undefined;

# go through each of the headwords in the headword cache

for (values %cache)
{

	my @array = @$_;

	for (@array)
	{
		$uniq{$_} = 1;
	}
}

for ( keys %uniq )
{
	# check lewis for an entry

	my $semantic_tags = $lewis{$_};

#	print "\$lewis{$_} = $lewis{$_}\n";

	if ( defined $semantic_tags )
	{
		$count{'defined'}++;
	}
	else
	{
		$count{'undefined'}++;
		push @undefined, $_;
	}
}

for (sort @undefined)
{
	print "$_\n";
}

for (sort keys %count)
{
	print "$_\t$count{$_}\n";
}
