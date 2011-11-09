use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';

use Storable qw(nstore retrieve);

use TessSystemVars;

use Files;
use Word;
use Phrase;

my $source = shift @ARGV || 'aeneid1';

$source =~ s/.+\///;
$source =~ s/\.tess//;

my $file_stems 	= "$fs_data/common/la.stem.cache";
my $file_semantic = "$fs_data/common/la.semantic.cache";

my $file_parsed 	= "$fs_data/v2/parsed/$source.parsed";


my %stem 	 = %{ retrieve($file_stems) };
my %semantic = %{ retrieve($file_semantic) };

my %uniq;
my %count;

for ( values %stem )
{
	for (@{$_})
	{
		$uniq{$_} = 1;
	}
}

for my $key (keys %uniq)
{
	$key =~ s/[^a-z ]//ig;

	my $test = defined $semantic{lc($key)} ? 'defined' : 'undefined';

	push @{$count{$test}}, $key;
}

for (sort keys %count)
{
	print scalar(@{$count{$_}}) . " $_ : " . join (", ", @{$count{$_}}[0..9], "...") . "\n";
}
