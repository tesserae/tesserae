#
# engl_word_count.pl
#
# read the cache of definitions produced by read-full-lewis.pl
# and create frequency counts for english words in definitions

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

use lib $fs{perl};

use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);

#
# load the cache of definitions
#

my $file = shift @ARGV || catfile($fs{data}, 'common', 'la.semantic.cache');

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

my $file_count = shift @ARGV || catfile($fs{data}, 'common', 'la.semantic.count');

print STDERR "writing $file_count\n";
nstore \%count, $file_count;

