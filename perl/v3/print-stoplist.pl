# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# print a frequency list
#

use strict;
use warnings;

use CGI qw/:standard/;

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);

use TessSystemVars;
use EasyProgressBar;

my $corpus  = 0;
my $file    = '';
my $mode    = 'stop';
my $score   = 0;
my $feature = 'stem';

GetOptions( 'corpus=s'  => \$corpus,
			'score'     => \$score,   
			'feature=s' => \$feature );

$mode = 'score' if ($score and not $corpus);

$file = shift @ARGV;

if ($corpus) {

	$file = catfile($fs_data, 'common', "$corpus.$feature.freq");
}
else {

	my $file_lang = catfile($fs_data, 'common', 'lang');
	my %lang = %{retrieve($file_lang)};

	$file = catfile($fs_data, 'v3', $lang{$file}, $file, "$file.freq_${mode}_$feature");
	
	unless (-s $file) {
	
		print STDERR "can't read frequency list $file: $!\n";
		print STDERR "usage: perl print-stoplist.pl [--score] [--feature FEATURE] FILE\n";
		print STDERR "       perl print [--feature FEATURE] --corpus LANG\n\n";
	}
}

my %freq = %{retrieve($file)};

for my $key (sort {$freq{$b} <=> $freq{$a}} keys %freq) {

	print sprintf("%.8f\t%s\n", $freq{$key}, $key);
}
