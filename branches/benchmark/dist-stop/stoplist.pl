#! /usr/bin/perl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

#
# stoplist.pl
#
# print the current stoplist
#

use strict;
use warnings;

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

# source means the alluded-to, older text

my $source = "vergil.aeneid";

# target means the alluding, newer text

my $target = "lucan.pharsalia.part.1";

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = "line";

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = "stem";

# stopwords is the number of words on the stoplist

my $stopwords = 10;

# from is the basis for calculating the stoplist

my $from = 'target';

GetOptions( 
			'source=s'    => \$source,
			'target=s'    => \$target,
			'unit=s'      => \$unit,
			'feature=s'   => \$feature,
			'stopwords=i' => \$stopwords, 
			'from=s'      => \$from
			);

# language database

my $file_lang = catfile($fs_data, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

#
# calculate feature frequencies
#

my $file_freq;

# frequencies for the whole corpus
if ($from eq "corpus") {

	$file_freq = catfile($fs_data, 'common', 'la.'.$feature.'.freq');
}

# frequencies for the target text

elsif ($from eq "target") {
	
	$file_freq = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_' . $feature);
}

elsif ($from eq "source") {

	$file_freq = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_' . $feature);
}	

my %freq = %{retrieve( $file_freq)};

#
# create stop list
#

my @stoplist = sort {$freq{$b} <=> $freq{$a}} keys %freq;

if ($stopwords > 0) {
	
	@stoplist = @stoplist[0..$stopwords-1];
}
else {
	
	@stoplist = ();
}

my $count = 0;

for (@stoplist) {

	$count ++;
	
	print join("\t", $count, $_, sprintf("%.4f", $freq{$_})) . "\n";
}
