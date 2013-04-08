# parse the dictionary file for whitaker's words
# and use the english defs for semantic tags

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

my $file_semantic	= catfile($fs{data}, 'common', 'la.semantic.cache');
my $file_stem		= catfile($fs{data}, 'common', 'la.stem.cache');
my $file_count		= catfile($fs{data}, 'common', 'la.word_count');
my $file_whitaker	= catfile($fs{data}, 'common', 'DICTPAGE.RAW');


my %count	= %{ retrieve($file_count) };
my %stem	= %{ retrieve($file_stem)  };

my %tesserae;

for my $form (	keys %count ) {

	if (defined $stem{$form}) {
		
		for (@{$stem{$form}}) {
			
			$tesserae{$_} = 1;
		}
	}
	else {
		
		$tesserae{$form} = 1;
	}
}

print "tesserae has " . scalar(keys %tesserae) . " forms to look up\n";

#
# parse whitaker
#

my %whitaker;

open FH, $file_whitaker;

while (<FH>) {
	
	chomp;
	
	if (/\#(\S+)[,\s].*:: (.+)/) {
		
		my ($key, $def) = ($1, $2);
		
		$whitaker{$key} = $def;
	}
}

close FH;

print "whitaker has " . scalar(keys %whitaker) . " entries\n";

#
# associate the defs with the tesserae words
#

my %def;

for (keys %tesserae) {
	
	$def{$_} = $whitaker{$_};
}

print scalar(keys %def) . "/" . scalar(keys %tesserae) . " tesserae words have defs\n";

nstore \%def, $file_semantic;
