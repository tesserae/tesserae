#!/usr/bin/perl

use lib '/home/forstall/chris/perl/';
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use Frontier::Client;
use Storable;
use Files;


my $readfromfile = 1;
my $showprogress = 1;
my $verbose = 0; # 0 == only 5/10; 1 == 0 - 10; 2 == -1 - 10

my $usage = "usage: to prepare a corpus: ./preprocess.pl -p [label for source] [label for target]";

# the following variable controls how many stems (or words) in common constitute an 'interesting' parallel
my $interesting_parallel_threshold = 2;

# determine command line arguments
my @text;
my $numberoftexts = 0;
my $numberofflags = 0;
if ($#ARGV+1 < 1) {
	print $usage;
	exit;
}
for (my $i=0; $i<$#ARGV+1; $i++) {
	if (!(substr($ARGV[$i], 0, 1) eq '-')) {
		$text[$numberoftexts] = $ARGV[$i];
		$numberoftexts++;
	}
}
if ($numberoftexts != 2) {
	print $usage;
	exit;
}

# print STDERR "file 1: ".$text[0]."\nfile 2: ".$text[1]."\noutput: ".$text[2]."\n\n";

my $parsed_source = $fs_data . 'v2/parsed/' . Files::source_parsed_file($text[0], $text[1]);
my $parsed_target = $fs_data . 'v2/parsed/' . Files::target_parsed_file($text[0], $text[1]);
my $preprocessed_file = $fs_data . 'v2/preprocessed/' . Files::preprocessed_file($text[0], $text[1]);
my $num_arguments = $#ARGV + 1;

# code for testing Files
if (Files::determine_input_filenames($text[0], $text[1]) == 0) {
	print "ERROR: either the source or the target label cannot be found in the\n";
	print "       configuration file.\n\n";
	print "I used configuration file ".Files::config_file().".\n";
	print "This typically occurs if a text has been prepared but the comparison pair has \n";
	print "not been added yet to the config file.\n";
	print "See the documentation in Files.pm for more information on the format of the \n";
	print "configuration file.";
	print "exiting.\n";
	die;
	
} else {
	print "source label: ".$text[0]."\n";
	print "target label: ".$text[1]."\n";
	print "source prs file: " . $parsed_source . "\n";
	print "target prs file: " . $parsed_target . "\n";
	print "output file: " . $preprocessed_file . "\n";
}

my @parallels;
my $total_num_matches = 0;

# the actual parsing is now done in prepare.pl. The results are read in in the lines below.
my @phrases1array = @{retrieve($parsed_source)};
my @phrases2array = @{retrieve($parsed_target)};
my @wordset_array;
my $window=3;
print "parsed texts\n";

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
system("date");
print "begin; num phrases in texts 1 (".$parsed_source.") and 2 (".$parsed_target."): ".$num_phrases_text1." and ".$num_phrases_text2."\n";
print "total number of comparisons to be made: ".$num_phrases_text1 * $num_phrases_text2."\n";

foreach (@phrases1array) {
	my $phrase1 = $_;
	bless ($phrase1, "Phrase");
	if ($showprogress == 1) {
		# print "finding parallels for phrase A:   ";
		# $phrase1->short_print();
		# print "\n";
	}
	# print "    to \n";
#	if (scalar @{$phrase1->{WORDARRAY}} >= 2 && scalar @parallels < 90000) {
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
print "# of interesting parallels (threshold: $interesting_parallel_threshold): ".scalar(@parallels)." (".scalar(@parallels) / ($num_phrases_text1 * $num_phrases_text2).")\n";
system("date");

# serialize and store with Storable
use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);
nstore \@parallels, $preprocessed_file;

=head4 subroutine: parse_text(filename)

Usage: 

  parse_text(filename).

This subroutine reads in F<filename> and parses it. It returns a structure of type ..

=cut 




