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

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);

#
# set some parameters
#

my $lang = 'la';

my $file_cache = catfile($fs{data}, 'common', "$lang.stem.cache");

my %stem = %{retrieve($file_cache)};

print STDERR "removing stems which compete with \"sum\" from the stem dictionary\n";

for (keys %stem) {

	if ( grep {/^sum$/} @{$stem{$_}}) {
	
		$stem{$_} = ['sum'];
	}
}

nstore \%stem, $file_cache;
