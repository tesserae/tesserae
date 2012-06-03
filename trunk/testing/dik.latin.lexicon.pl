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

use Storable qw(nstore retrieve);

my %stem;

print STDERR "reading csv file...\n";

my $final = 1220933;
my $counter = 0;
my $progress = 0;

print STDERR (" " x 43) . "| 100%\r0% |";

open FH, "<latinlexicon.csv";

while (my $line = <FH>) {

	chomp $line;
	my @field = split /,/, $line;
	
	my ($token, $grammar, $headword) = @field[1,2,3];
	
	$token = lc($token);
	$token =~ tr/jv/iu/;
	
	$headword = lc($headword);
	$headword =~ tr/jv/iu/;
	$headword =~ s/[^a-z]//g;
	
	push @{$stem{$token}}, $headword;
	
	$counter++;
	
	if ($counter/$final > $progress + .025) {
		
		print STDERR ".";
		
		$progress = $counter/$final;
	}
}

print STDERR "\n";

close FH;

print STDERR "rationalizing headwords...\n";

$final = scalar(keys %stem);
$counter = 0;
$progress = 0;

print STDERR (" " x 43) . "| 100%\r0% |";

for my $headword (keys %stem) {

	my %uniq;
	
	for (@{$stem{$headword}}) {

		$uniq{$_} = 1;
	}
		
	$stem{$headword} = [(keys %uniq)];
	
	$counter++;
	
	if ($counter/$final > $progress + .025) {
		
		print STDERR ".";
		
		$progress = $counter/$final;
	}	
}

print STDERR "\n";

print STDERR "saving...";

nstore \%stem, "la.stem.cache";

print STDERR "\n";