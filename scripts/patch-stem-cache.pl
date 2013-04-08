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

# variables set from config

my %fs;
my %url;
my $lib;

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $config = catfile($lib, 'tesserae.conf');
		
	until (-s $config) {
					
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			$config = catfile($lib, 'tesserae.conf');
			
			next;
		}
		
		die "can't find tesserae.conf!\n";
	}
	
	# read configuration
		
	my %par;
	
	open (FH, $config) or die "can't open $config: $!";
	
	while (my $line = <FH>) {
	
		chomp $line;
	
		$line =~ s/#.*//;
		
		next unless $line =~ /(\S+)\s*=\s*(\S+)/;
		
		my ($name, $value) = ($1, $2);
			
		$par{$name} = $value;
	}
	
	close FH;
	
	# extract fs and url paths
		
	for my $p (keys %par) {

		if    ($p =~ /^fs_(\S+)/)		{ $fs{$1}  = $par{$p} }
		elsif ($p =~ /^url_(\S+)/)		{ $url{$1} = $par{$p} }
	}
}

# load Tesserae-specific modules

use lib $fs{script};

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
