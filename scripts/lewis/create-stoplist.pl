#
# create-stoplist.pl
#
# read the cache of definitions produced by read-full-lewis.pl
# and create frequency counts for the definitions

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

use TessSystemVars;

use Storable qw(nstore retrieve);

#
# load the cache of definitions
#

my $file_def = shift @ARGV || "$fs_data/common/la.semantic.cache";
print STDERR "reading $file_def\n";
my %def 	= 	%{ retrieve($file_def)  };

print STDERR scalar(keys %def) . " keys have at least one definition\n";

#
# count definitions, words in each entry
#

my %count_def;

for (keys %def)
{
	for (@{$def{$_}})
	{
		$count_def{$_}++;	
	}
}

print STDERR scalar(keys %count_def) . " unique definitions\n";

#
# write definition counts
#

my $file_count = shift @ARGV || "stoplist.txt";

print STDERR "writing $file_count\n";
open FH, ">count-def.txt";

# this allows unicode output
binmode FH, ":utf8";

for ( sort {$count_def{$b} <=> $count_def{$a}} keys %count_def )
{
	print FH "$count_def{$_}\t$_\n"
}

close FH;
