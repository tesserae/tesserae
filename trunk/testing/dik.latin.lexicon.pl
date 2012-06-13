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

use lib '/Users/chris/Sites/tesserae/perl';
use TessSystemVars;
use EasyProgressBar;

use Storable qw(nstore retrieve);

my $file_csv = "$fs_data/common/latinlexicon.csv";
my $file_cache = "$fs_data/common/la.stem.cache";

my %stem;

print STDERR "reading csv file: $file_csv\n";

open (FH, "<", $file_csv) || die "can't open csv: $!";

my $pr = ProgressBar->new(-s $file_csv);

while (my $line = <FH>) {
	
	$pr->advance(length($line));

	chomp $line;
	my @field = split /,/, $line;
	
	my ($token, $grammar, $headword) = @field[0..2];
	
	$token = lc($token);
	$token =~ tr/jv/iu/;
	
	$headword = lc($headword);
	$headword =~ tr/jv/iu/;
	$headword =~ s/[^a-z]//g;
	
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