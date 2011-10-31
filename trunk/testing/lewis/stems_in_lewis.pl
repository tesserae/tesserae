use strict;
use warnings;

use lib '/var/www/tesserae/perl';

use Storable qw(nstore retrieve);

use TessSystemVars;

use Files;
use Word;
use Phrase;

my $source = shift @ARGV || 'aeneid1';

$source =~ s/.+\///;
$source =~ s/\.tess//;

my $file_stems = Files::cache_filename();
my $file_lewis = $fs_data . 'v2/lewis.cache';

my $file_parsed = $fs_data . 'v2/parsed/' . $source . '.parsed';


my %stems = %{ retrieve($file_stems) };
my %lewis = %{ retrieve($file_lewis) };

my %uniq;
my %count;

for ( values %stems )
{
	for (@{$_})
	{
		$uniq{$_} = 1;
	}
}

for my $key (keys %uniq)
{
	$key =~ s/[^a-z ]//ig;

	my $test = defined $lewis{lc($key)} ? 'defined' : 'undefined';

	push @{$count{$test}}, $key;
}

for (sort keys %count)
{
	print scalar(@{$count{$_}}) . " $_ : " . join (", ", @{$count{$_}}[0..9], "...") . "\n";
}
