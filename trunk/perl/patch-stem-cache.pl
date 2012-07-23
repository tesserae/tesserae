# 
# this script is a hack to get edo out of the stoplist
#
# - find all the words that have both edo and sum as 
#   possible stems, and delete edo.
# - the justification for this is that edo is put on
#   the stoplist anyway, thanks to these words, so
#   they're never going to match it; might as well
#   cut our losses and allow the unambiguous cases
#   of edo to have a chance an matching.
#
# Chris Forstall
# 2012-07-23

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use EasyProgressBar;

use Storable qw(nstore retrieve);

my $lang = 'la';

my $file_cache = "$fs_data/common/$lang.stem.cache";

my %stem = %{retrieve($file_cache)};

print STDERR "removing stems which compete with \"sum\" from the stem dictionary\n";

for (keys %stem) {

	if ( grep {/^sum$/} @{$stem{$_}}) {
	
		$stem{$_} = ['sum'];
	}
}
