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

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);
use Encode;

#
# initialize some parameters
#

my @lang = @ARGV ? @ARGV : qw/la/;

my $quiet = 0;

# command-line options

GetOptions(
	'quiet'  => \$quiet);

#
# process each language
#

for my $lang (@lang) {

	my $file_csv   = catfile($fs{data}, 'common', "$lang.lexicon.csv");
	my $file_cache = catfile($fs{data}, 'common', "$lang.stem.cache");
	
	my %stem;
	
	print STDERR "reading csv file: $file_csv\n" unless $quiet;
	
	open (FH, "<:utf8", $file_csv) || die "can't open csv: $!";
	
	my $pr = ProgressBar->new(-s $file_csv, $quiet);
	
	while (my $line = <FH>) {
		
		$pr->advance(length(Encode::encode('utf8', $line)));
	
		# NOTE:
		# what's the significance of quotation marks?
		
		$line =~ s/"//g;
		
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
	
	print STDERR "rationalizing headwords...\n" unless $quiet;
	
	$pr = ProgressBar->new(scalar(keys %stem), $quiet);
	
	for my $headword (keys %stem) {
	
		$pr->advance();
	
		my %uniq;
		
		for (@{$stem{$headword}}) {
	
			$uniq{$_} = 1;
		}
			
		$stem{$headword} = [(keys %uniq)];
		
	}
	
	print STDERR "saving: $file_cache" unless $quiet;
	
	nstore \%stem, $file_cache;
	
	print STDERR "\n" unless $quiet;
}