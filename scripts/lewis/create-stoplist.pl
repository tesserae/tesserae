#
# create-stoplist.pl
#
# read the cache of definitions produced by read-full-lewis.pl
# and create frequency counts for the definitions

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
	
	my $config;
	my $pointer;
			
	while (1) {

		$config  = catfile($lib, 'tesserae.conf');
		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-s $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$config = <FH>;
			
			chomp $config;
			
			last;
		}
		
		last if (-s $config);
							
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
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
# load the cache of definitions
#

my $file_def = shift @ARGV || catfile($fs{data}, 'common', 'la.semantic.cache');
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
