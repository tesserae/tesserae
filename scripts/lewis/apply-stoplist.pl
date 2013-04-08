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
# load data
#

# open the file

my $file = shift @ARGV;

open (FH, "<$file") || die "can't open $file: $!";

# load the definitions from the cache

my $cache = shift @ARGV || catfile($fs{data}, 'common', 'la.semantic.cache');

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
