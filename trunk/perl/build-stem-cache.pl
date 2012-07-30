# dik.latin.lexicon.pl
# 
# Chris Forstall
# 2012-05-08 (revised)
#
# The purpose of this script is to turn Helma Dik's lexicon database
# into a cached stem dictionary in Storable binary format for use
# with Tesserae.  This will be build into the svn repository in order
# to remove the need for Frontier::Client, which is used to get
# stems from the Archimedes server but is kind of a hassle to install.

use strict;
use warnings;

use lib '/Users/chris/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use EasyProgressBar;

use Storable qw(nstore retrieve);
use File::Spec::Functions;

my $lang = (shift @ARGV) || 'la';

my $file_csv   = catfile($fs_data, 'common', "$lang.lexicon.csv");
my $file_cache = catfile($fs_data, 'common', "$lang.stem.cache");

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
	
	$token = TessSystemVars::standardize($lang, $token);
	
	$headword = TessSystemVars::standardize($lang, $headword);
	
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