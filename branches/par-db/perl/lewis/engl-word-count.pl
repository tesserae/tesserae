#
# engl_word_count.pl
#
# read the cache of definitions produced by read-full-lewis.pl
# and create frequency counts for english words in definitions

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

use TessSystemVars;

use Storable qw(nstore retrieve);

#
# load the cache of definitions
#

my $file = shift @ARGV || "$fs_data/common/la.semantic.cache";

print STDERR "loading $file\n";
my %def 	= 	%{ retrieve("$file")  };

print STDERR "reading " . scalar(keys %def) . " entries\n";

#
# count definitions, words in each entry
#

my %count;

for (keys %def)
{
	for (@{$def{$_}})
	{
		my @words = split /[^a-zA-Z]+/, $_;

		for (@words)
		{
			$count{lc($_)}++;
		}
	}
}

print STDERR scalar(keys %count) . " english words\n";

#
# cache word count with Storable
#

my $file_count = shift @ARGV || "$fs_data/common/la.semantic.count";

print STDERR "writing $file_count\n";
nstore \%count, $file_count;

