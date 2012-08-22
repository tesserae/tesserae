#! /opt/local/bin/perl5.12

use lib '/var/www/tesserae/perl';
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use Frontier::Client;
use Storable qw(nstore retrieve);
use Files;

my $showprogress = 0;

my $usage = "usage: to compare two files: ./preprocess.pl SOURCE TARGET";

# the following variable controls how many stems (or words) in common constitute an 'interesting' parallel
my $interesting_parallel_threshold = 2;

# determine command line arguments
my @text = @ARGV;

if ($#text < 1)
{
	die $usage;
}

# get the appropriate comparison file for these texts,
# append the local path

my $parsed_source = $fs_data . 'v2/parsed/' . Files::source_parsed_file($text[0], $text[1]);
my $parsed_target = $fs_data . 'v2/parsed/' . Files::target_parsed_file($text[0], $text[1]);
my $preprocessed_file = $fs_data . 'v2/preprocessed/' . Files::preprocessed_file($text[0], $text[1]);


# code for testing Files
if (Files::determine_input_filenames($text[0], $text[1]) == 0) {

	my $message = 

		"ERROR: either the source or the target label cannot be found in the\n"
		. "       configuration file.\n\n"
		. "I used configuration file ".Files::config_file().".\n"
		. "This typically occurs if a text has been prepared but the comparison pair has \n"
		. "not been added yet to the config file.\n"
		. "See the documentation in Files.pm for more information on the format of the \n"
		. "configuration file."
		. "exiting.\n";

	die $message;
	
} else {
	print STDERR "source label: ".$text[0]."\n";
	print STDERR "target label: ".$text[1]."\n";
	print STDERR "source prs file: " . $parsed_source . "\n";
	print STDERR "target prs file: " . $parsed_target . "\n";
	print STDERR "output file: " . $preprocessed_file . "\n\n";
}

my @parallels;
my $total_num_matches = 0;

# the actual parsing is now done in prepare.pl. The results are read in in the lines below.
my @phrases1array = @{retrieve($parsed_source)};
my @phrases2array = @{retrieve($parsed_target)};
my @wordset_array;
my $window=3;

print STDERR "parsed texts\n\n";

# determine the number of phrases in each text
my $num_phrases_text1 = scalar @phrases1array;
my $num_phrases_text2 = scalar @phrases2array;

print STDERR "begin: " . localtime(time) . "\n\n";

print STDERR "num phrases in texts 1 ($parsed_source) and 2 ($parsed_target): ";
print STDERR "$num_phrases_text1 and  $num_phrases_text2 \n";
print "total number of comparisons to be made: ".$num_phrases_text1 * $num_phrases_text2."\n\n";

# draw a progress bar

my $progress = 0;
my $pcounter = 0;

if ($showprogress == 1)
{
	print STDERR "0% |" . (" "x25) . "| 100%\r0% |";
}

#
# main loop
#
# compare every stem of every word of every phrase in the source text
# with every stem of every word of every phrase in the target text

foreach (@phrases1array[0]) {

	my $phrase1 = $_;
	bless ($phrase1, "Phrase");

	# advance the progress bar

	if ($showprogress == 1) {

		$pcounter++;
		
		if (($pcounter/$#phrases1array) > $progress + .04)
		{
			
			print STDERR ".";
			
			$progress += .04;
		}
	}
	
	# only consider phrases with two or more words

	if (scalar @{$phrase1->{WORDARRAY}} >= 2) {

		# compare each to each phrase in the second text

		foreach (@phrases2array[0]) {

			my $phrase2 = $_;
			bless ($phrase2, "Phrase");

			if ($phrase2 == 0) {
				die "ERROR: phrase2 is NULL where it should contain a phrase.\n";
			}
			if ($phrase2->{WORDARRAY} == 0) {
				die "ERROR: phrase2->{WORDARRAY} is NULL where it should contain a phrase.\n";
			}

			# make sure second phrase has at least two words

			if (scalar @{$phrase2->{WORDARRAY}} >= 2) {

				# do the comparison, save the result if enough words in common


				print $phrase1->phrase . "\n";
				print $phrase2->phrase . "\n";
				print "score: " . $phrase1->semantic_comparison($phrase2) . "\n";

				# if ($phrase1->compare($phrase2) >= $interesting_parallel_threshold ) {
				# 
				# 					my $parallel = Parallel->new();
				# 
				# 					$parallel->phrase_a($phrase1);
				# 					$parallel->phrase_b($phrase2);
				# 
				# 					push @parallels, $parallel;
				# 				}
			}
		}
	}
}

# finish the progress bar

if ($showprogress == 1)
{
	print "\n";
}

print STDERR "# of interesting parallels (threshold: $interesting_parallel_threshold): " . scalar(@parallels);
print STDERR  sprintf("%.2f\n\n", (scalar(@parallels) / ($num_phrases_text1 * $num_phrases_text2)));

# save the set of parallels

print "saving $preprocessed_file\n\n";

nstore \@parallels, $preprocessed_file;

print STDERR "finished: " . localtime(time) . "\n";
