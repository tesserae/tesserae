#
# apply-stoplist.pl
#
# use a stoplist created by create-stoplist.pl
# to remove certain dictionary definitions from
# the cache created by read-full-lewis.pl

#
# specify the file with the stoplist on the cmd line
#
# it's expected to have this format:
# count	definition
#
# i.e. a number followed by a tab, then the definition,
# but it should work also on a file without the counts,
# just one definition per line.

use lib '/Users/chris/sites/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

use TessSystemVars;

use Storable qw(nstore retrieve);

#
# load data
#

# open the file

my $file = shift @ARGV;

open (FH, "<$file") || die "can't open $file: $!";

# load the definitions from the cache

my $cache = shift @ARGV || "$fs_data/common/la.semantic.cache";

print STDERR "loading $cache\n";

my %def = %{ retrieve($cache) };

print STDERR scalar(keys %def) . " headwords defined\n";


#
# here we create a new hash that's the inverse of the old one:
# - the keys are definitions
# - the values are anonymous arrays of headwords under which 
#   a given definition appears

print STDERR "processing\n";

my %inverse;

for my $headword (keys %def)
{
	for my $definition (@{$def{$headword}})
	{
		push @{$inverse{$definition}}, $headword;
	}
}

#
# now read the stoplist and delete from the inverse hash keys 
# that match the list

print STDERR "applying stoplist $file\n";

my $defs_count = scalar(keys %inverse);

while (my $line = <FH>)
{
	if ($line =~ /^(?:\d+\t)?(.+)/)
	{
		my $definition = $1;
		
		if (defined $inverse{$definition})
		{
			delete $inverse{$definition};
		}
	}
}

print sprintf("%i", $defs_count - scalar(keys %inverse)) . " definitions deleted\n";

#
# now rebuild the original hash by re-inverting the new hash
# 

print STDERR "rebuilding cache\n";

%def = ();

for my $definition (keys %inverse)
{
	for my $headword (@{$inverse{$definition}})
	{
		push @{$def{$headword}}, $definition;
	}
}


#
# save the new, slimmer hash
# 

print STDERR scalar(keys %def) . " headwords still have at least one definition\n";

nstore \%def, $cache;
