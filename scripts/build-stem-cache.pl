# build-stem-cache.pl
# 
# Chris Forstall
# 2012-05-08 (revised)
# 2013-03-29 revised
#
# The purpose of this script is to turn Helma Dik's lexicon database
# into a cached stem dictionary in Storable binary format for use
# with Tesserae.  
#
# Replaced the old system which used the Archimedes service to get
# stems over the Internet.

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
# initialize some parameters
#

my $lang = (shift @ARGV) || 'la';

my $file_csv   = catfile($fs{data}, 'common', "$lang.lexicon.csv");
my $file_cache = catfile($fs{data}, 'common', "$lang.stem.cache");

my %stem;

print STDERR "reading csv file: $file_csv\n";

open (FH, "<", $file_csv) || die "can't open csv: $!";

my $pr = ProgressBar->new(-s $file_csv);

while (my $line = <FH>) {
	
	$pr->advance(length($line));

	# skip lines whose tokens are in quotation marks
	# these employ characters with accent marks

	next if $line =~ /^"/;
	
	# remove newline

	chomp $line;
	
	# split on commas
	
	my @field = split /,/, $line;
	
	my ($token, $grammar, $headword) = @field[0..2];
	
	# standardize the forms
	
	$token = Tesserae::standardize($lang, $token);
	
	$headword = Tesserae::standardize($lang, $headword);
	
	# add to dictionary
	
	push @{$stem{$token}}, $headword;
}

close FH;

print STDERR "rationalizing headwords...\n";

$pr = ProgressBar->new(scalar(keys %stem));

for my $headword (keys %stem) {

	$pr->advance();

	my %uniq;
	
	for (@{$stem{$headword}}) {

		$uniq{$_} = 1;
	}
		
	$stem{$headword} = [(keys %uniq)];
	
}

print STDERR "saving: $file_cache";

nstore \%stem, $file_cache;

print STDERR "\n";
