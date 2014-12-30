# 
# Language-specific patches
#
# Chris Forstall
# 2012-07-23
# rev 2013-09-21

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
	
	$lib = catdir($lib, 'TessPerl');	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);
use Unicode::Normalize;
use utf8;

binmode STDERR, ':utf8';

#
# Latin: remove words that conflict with sum
#

{
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
}

