#!/usr/bin/perl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Storable qw(nstore retrieve);


my $readfromfile = 1;
my $showprogress = 1;
my $verbose = 0; # 0 == only 5/10; 1 == 0 - 10; 2 == -1 - 10

my $usage = "usage: to prepare a corpus: ./preprocess.pl [label for source] [label for target]";

# the following variable controls how many stems (or words) in common constitute an 'interesting' parallel
my $interesting_parallel_threshold = 2;

# determine command line arguments
my @text;
my $numberoftexts = 0;
my $numberofflags = 0;
if ($#ARGV+1 < 1) {
	print STDERR $usage;
	exit;
}
for (my $i=0; $i<$#ARGV+1; $i++) {
	if (!(substr($ARGV[$i], 0, 1) eq '-')) {
		$text[$numberoftexts] = $ARGV[$i];
		$numberoftexts++;
	}
}
if ($numberoftexts != 2) {
	print STDERR $usage;
	exit;
}

# print STDERR "file 1: ".$text[0]."\nfile 2: ".$text[1]."\noutput: ".$text[2]."\n\n";

my $parsed_source = "$fs_data/v2/parsed/$text[1].parsed";
my $parsed_target = "$fs_data/v2/parsed/$text[0].parsed";
my $preprocessed_file = "$fs_data/v2/preprocessed/" . join("~", sort @text[0,1]) . ".preprocessed";
my $num_arguments = $#ARGV + 1;

print STDERR "source label: ".$text[0]."\n";
print STDERR "target label: ".$text[1]."\n";
print STDERR "source prs file: " . $parsed_source . "\n";
print STDERR "target prs file: " . $parsed_target . "\n";
print STDERR "output file: " . $preprocessed_file . "\n";

my @parallels;
my $total_num_matches = 0;

# the actual parsing is now done in prepare.pl. The results are read in in the lines below.
my @phrases1array = @{retrieve($parsed_source)};
my @phrases2array = @{retrieve($parsed_target)};
my @wordset_array;
my $window=3;
print STDERR "parsed texts\n";

# swap arrays if one is larger than the other. Commented out now that parse_text returns phrases
#if (scalar(@phrases1array) < scalar(@phrases2array)) { #}
#	my @tempwordarray = @word1array;
#	@word1array = @word2array;
#	@word2array = @tempwordarray;
# }

# determine the number of phrases in each text
my $num_phrases_text1 = scalar @phrases1array;
my $num_phrases_text2 = scalar @phrases2array;
#foreach (@word1array) { #}
#	if ($_->phraseno() > $num_phrases_text1) {$num_phrases_text1 = $_->phraseno};
#}
#my $num_phrases_text2 = 0;
#foreach (@word2array) { #}
#	if ($_->phraseno() > $num_phrases_text2) {$num_phrases_text2 = $_->phraseno};
#}
print STDERR "begin " . localtime($^T) . "\n";
print STDERR "num phrases in text 1 ($parsed_source): $num_phrases_text1\n";
print STDERR "num phrases in text 2 ($parsed_target): $num_phrases_text2\n";
print STDERR "total number of comparisons to be made: " . ($num_phrases_text1 * $num_phrases_text2) . "\n";

# draw a progress bar

my $progress_this = 0;
my $progress_last  = 0;

print STDERR (" "x24) . "| 100%" . "\r" . "0% |";

# main loop

foreach (@phrases1array) {

	if ($showprogress == 1) {
		if ($progress_this++ / $#phrases1array > $progress_last+.05)
		{
			print STDERR ".";
			$progress_last = $progress_this / $#phrases1array;
		}
	}

	my $phrase1 = $_;
	bless ($phrase1, "Phrase");

	if (scalar @{$phrase1->{WORDARRAY}} >= 2) {
		foreach (@phrases2array) {
			my $phrase2 = $_;
			bless ($phrase2, "Phrase");
			# print "          phrase B:";
			# $phrase2->short_print();
			# print "\n";
			if ($phrase2 == 0) {
				die "ERROR: phrase2 is NULL where it should contain a phrase.\n";
			}
			if ($phrase2->{WORDARRAY} == 0) {
				die "ERROR: phrase2->{WORDARRAY} is NULL where it should contain a phrase.\n";
			}
			if (scalar @{$phrase2->{WORDARRAY}} >= 2) {
				# print "          comparison result: ";
				# print $phrase1->compare($phrase2);
				# print "\n";
				if ($phrase1->compare($phrase2) >= $interesting_parallel_threshold ) {
					my $parallel = Parallel->new();
					$parallel->phrase_a($phrase1);
					$parallel->phrase_b($phrase2);
					push @parallels, $parallel;
				}
			}
		}
	}
}

print STDERR "\n\n";

print STDERR "# of interesting parallels (threshold: $interesting_parallel_threshold): " . scalar(@parallels);
print STDERR sprintf("(%.2f %%)", scalar(@parallels) / ($num_phrases_text1 * $num_phrases_text2)) . "\n\n";

print STDERR "writing $preprocessed_file\n";

# serialize and store with Storable
nstore \@parallels, $preprocessed_file;

print STDERR "\n";
print STDERR "finished " . localtime(time) . "\n";
print STDERR "total processing time: " . sprintf("%.1f", (time-$^T)/60) . " minutes\n";

=head4 subroutine: parse_text(filename)

Usage: 

  parse_text(filename).

This subroutine reads in F<filename> and parses it. It returns a structure of type ..

=cut 




