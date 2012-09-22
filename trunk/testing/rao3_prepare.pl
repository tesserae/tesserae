#! /opt/local/bin/perl5.12

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
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


my $readfromfile = 0;
my $showprogress = 1;
my $writecsv = 0;
my $verbose = 0; # 0 == only 5/10; 1 == 0 - 10; 2 == -1 - 10

my $usage = "usage: to prepare a corpus: ./prepare.pl [-r] [-c] <input file> [<output: parsed corpus file>]
  -r: instead of writing to <output: parsed corpus file>, 
      use that file for reading a previously generated file
  -c: create two CSV-files with stems and words statistics (named: 
      <input file>.words.statistics.csv and <input file>.stems.statistics.csv)\n";

# determine command line arguments
my @text;
my $numberoftexts = 0;
my $numberofflags = 0;
if ($#ARGV < 0) {
	print STDERR $usage;
	exit;
}
for (my $i=0; $i<$#ARGV+1; $i++) {
	if (!(substr($ARGV[$i], 0, 1) eq '-')) {
		$text[$numberoftexts] = $ARGV[$i];
		$numberoftexts++;
	} else {
		if ($ARGV[$i] eq '-r') {
			$readfromfile = 1;
		}
		if ($ARGV[$i] eq '-c') {
			$writecsv = 1;
		}
	}
	
}

if ($numberoftexts == 1)
{
	$text[1] = $text[0];
	$text[1] =~ s/.+\//${fs_data}v2\/parsed\//;
	$text[1] =~ s/(\.tess)?$/\.parsed/;
}
elsif ($numberoftexts != 2) 
{
	print STDERR $usage."\n";
	exit;
}

if ($readfromfile == 1) {
	print STDERR "Reading from file ".$text[1]."\n";
}

print STDERR "input file 1: ".$text[0]."\nparsed corpus output file: ".$text[1]."\n\n";

my $text = $text[0];
my $output_parsed_file = $text[1];
my $output_statistics_file = $text[2];
my $num_arguments = $#ARGV + 1;

# open cache for reading
my %cache = ();

if (-s Files::cache_filename()) 
{
	%cache = %{retrieve(Files::cache_filename())};
}

my @mykeys =keys %cache;
print STDERR "cache '".Files::cache_filename()."' contains ".$#mykeys." stems\n";

#use CGI qw/:standard/;

# on MAC
# my $text1="/Users/rao3/oldtesserae/svn/tesserae/trunk/line_numbered_texts/horace.epodes.tess";
# my $text2="/Users/rao3/oldtesserae/svn/tesserae/trunk/line_numbered_texts/catullus.carmina.tess";
# my $text2="/Users/rao3/oldtesserae/svn/tesserae/trunk/line_numbered_texts/vergil.aeneid.tess";
# my $text2 = "vergil.aeneid.book1.tess";
# my $text1="lucan.pharsalia.book1.tess";
#my $text2 = "vergil.10lines.tess";
#my $text1="lucan.10lines.tess";
my @parallels;
my $total_num_matches = 0;
my %words=();
my %stems=();

my @phrasesarray;

use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);

if ($readfromfile == 0) {
	print STDERR "parsing text: ".$text."\n";
	@phrasesarray = parse_text($text);
	my @wordset_array;
	my $window=3;
	nstore \@phrasesarray, $output_parsed_file;
	print STDERR "parsed text, written to file: $output_parsed_file.\n";
} else {
	@phrasesarray = @{retrieve($output_parsed_file)};
	
}
print STDERR "generating statistics...\n";
foreach (@phrasesarray) {
	my $phrase = $_;
	bless($phrase, "Phrase");
	my @wordarray = @{$phrase->wordarray()};
	foreach (@wordarray) {
		my $word = $_;
		bless($word, "Word");
#		print "word: ".$word->word()."\n";
		add_word($word->word);
		my @stemarray = @{$word->stemarray()};
		foreach my $stem (@stemarray) {
			add_stem($stem);
		}
	}
#	for ()
}

my $total_number_of_words = total_number_of_words();
my $total_number_of_stems = total_number_of_stems();
my @keys = keys %words;
my $total_number_of_distinct_words = scalar @keys;
@keys = keys %stems;
my $total_number_of_distinct_stems = scalar @keys;

print STDERR "Total number of words: ".$total_number_of_words."\n";
print STDERR "Total number of distinct words: ".$total_number_of_distinct_words."\n";
print STDERR "Total number of stems: ".$total_number_of_stems."\n";
print STDERR "Total number of distinct stems: ".scalar @keys."\n";

if ($writecsv == 1) {
	my $percent = 0;
	my $cum_percent = 0;
	my $rank = 0;
	my $relative_rank = 0;
	my $sep = ",";
	my $filename = $text[0].".words.statistics.csv";
	open (OUTPUT, ">".$filename);
	print OUTPUT "rank".$sep."relative rank".$sep."token frequency".$sep."relative token frequency".$sep."cumulative relative token frequency".$sep."token\n";
	foreach my $key (sort hashValueDescendingNum (keys(%words))) {
		$rank ++;
		$relative_rank = 100*($rank/$total_number_of_distinct_words);
		$percent = 100*($words{$key}/$total_number_of_words);
		$cum_percent += 100*($words{$key}/$total_number_of_words);

		printf OUTPUT ("%i%s", $rank, $sep);
		printf OUTPUT ("%.2f%s", $relative_rank, $sep);
		print OUTPUT "$words{$key}".$sep;
		printf OUTPUT ("%.2f%s%.2f%s", $percent, $sep, $cum_percent, $sep);
		print OUTPUT "$key\n";
	}
	close(OUTPUT);
	print STDERR "word statistics written to ".$filename."\n";


	$percent = 0;
	$cum_percent = 0;
	$rank = 0;
	$relative_rank = 0;
	$filename = $text[0].".stems.statistics.csv";
	
	open (OUTPUT, ">".$filename);
	print OUTPUT "rank".$sep."relative rank".$sep."token frequency".$sep."relative token frequency".$sep."cumulative relative token frequency".$sep."stem\n";
	foreach my $key (sort hashValueDescendingNum_stems (keys(%stems))) {
		$rank ++;
		$relative_rank = 100*($rank/$total_number_of_distinct_stems);
		$percent = 100*($stems{$key}/$total_number_of_stems);
		$cum_percent += 100*($stems{$key}/$total_number_of_stems);

		printf OUTPUT ("%i%s", $rank, $sep);
		printf OUTPUT ("%.2f%s", $relative_rank, $sep);
		print OUTPUT "$stems{$key}".$sep;
		printf OUTPUT ("%.2f%s%.2f%s", $percent, $sep, $cum_percent, $sep);
		print OUTPUT "$key\n";
	}
	close(OUTPUT);
	print STDERR "stems statistics written to ".$filename."\n";
	
}




# print "Words with their relative frequency: "


sub total_number_of_words {
	my $total_number = 0;
	for my $key (keys %words) {
		my $value = $words{$key};
		$total_number += $value;
	}
	return $total_number;
}

sub total_number_of_stems {
	my $total_number = 0;
	for my $key (keys %stems) {
		my $value = $stems{$key};
		$total_number += $value;
	}
	return $total_number;
}

# swap arrays if one is larger than the other. Commented out now that parse_text returns phrases
#if (scalar(@phrases1array) < scalar(@phrases2array)) { #}
#	my @tempwordarray = @word1array;
#	@word1array = @word2array;
#	@word2array = @tempwordarray;
# }

exit;

sub add_word {
	my $word = shift;
	if (exists $words{$word}) {
		# print "Word '".$word."' previously seen\n";
		$words{$word} = $words{$word}+1;
	} else {
		# print "Word '".$word."' is new\n";
		$words{$word} = 1;
	}
}

sub add_stem {
	my $stem = shift;
	if (exists $stems{$stem}) {
		# print "Word '".$word."' previously seen\n";
		$stems{$stem} = $stems{$stem}+1;
	} else {
		# print "Word '".$word."' is new\n";
		$stems{$stem} = 1;
	}
}

# serialize and store with Storable
# store \@parallels, $text[2];

=head4 subroutine: parse_text(filename)

Usage: 

  parse_text(filename).

This subroutine reads in F<filename> and parses it. It returns a structure of type ..

=cut 

sub parse_text {
	my @word_array;
	my @phrase_array;
	my $phraseno = 0;
	my $next=undef;
	my $prev=undef;
	
	my $filename = shift;
	open (TEXT, $filename) or die("Can't open file ".$filename);
	my $phrase=Phrase->new();
	while (<TEXT>) {
		
		chomp;
		# parse a line of text; reads in verse number and the verse. Assumption is that a line looks like:
		# <001> this is a verse
		my $verseno = $_;
		my $verse = $_;
		$verseno =~ s/\<(.+)\>(.*)/$1/s;
		$verse =~ s/\<(.+)\>\s*(.*)/$2/s;
		$verse =~ tr/A-Z/a-z/; # convert all to lowercase
		print STDERR $verseno." - ";
		# parse the words of the verse into an array
		my @words_array = split(' ', $verse);
		# UNCOMMENT FOR DEBUG: 
		# print "number of words: ".scalar @words_array."\n";
		# for each word, build a data structure of type Word
		foreach (@words_array) {
			my $word = Word->new();
			# remove punctuation 
			my $input_word = $_;
			$input_word =~ tr/,.\"\'?!:;//d;
			$word->word($input_word);
			$word->verseno($verseno);
			$word->phraseno($phraseno);
			if (defined($prev)) {
				$word->{PREVIOUS} = $$prev;
				$$prev->{NEXT} = $word;
			}
			$prev = \$word;
#			print STDERR "finding stems for input word $input_word";
			my @stems = find_stems($input_word);
			foreach (@stems) {
				$word->add_stem($_);
			}

			$phrase->add_word($word);
			
			# if punctuation found, increase phraseno.
			# string for ,.?!"';: is: [,\.\?\!\"\'\;:]
			# if (m/.*[,\.\?\!\"\'\;:]$/) {
			# currently only using end-of-line markers (.!?;:)
			if (m/.*[\.\?\!;:]$/) {
#			if (m/.*[\.]$/) {
				push @phrase_array, $phrase;
#				$phrase->print();
#				$phrase->short_print();
				$phraseno++;
				
				$phrase = Phrase->new();
				$prev=undef;;
			}
			push @word_array, \$word;
			# uncomment for debugging:
#			$word->print();
	#		print "prev is now: $prev";
		}
		print STDERR "\n";
		#print "\n";
	#	print "$_\n";
	}

#	foreach (@word_array) {
	#	print "verseno: ".$_->verseno()."\n";
#		if (defined($_->previous())) {
	#		print " <".$_->previous()->word()."> ";
#		} else {
	#		print " <"."null"."> ";
#		}
	#	print " ".$_->word()." ";
#		if (defined($_->next())) {
	#		print " <".$_->next()->word()."> ";
#		} else {
	#		print " <"."null"."> ";
#		}
	#	print "\n";

	#	print "word    : ".$_->word()."\n";
#	}
	close (TEXT);
	return @phrase_array;
	print STDERR "done\n";
	print STDERR "number of phrases: ".scalar @phrase_array."\n";
#	print Dumper(@phrase_array);
	my $prphrase = $phrase_array[3];
	print STDERR Dumper($prphrase);
	bless ($prphrase, "Phrase");
	$prphrase->print();
	foreach (@phrase_array) {
		my $phrase = $_;
		bless ($phrase, "Phrase");
		$phrase->short_print();
	}
	return @word_array;

}

sub find_stems {
	my $word = shift;
	my $debug = 0;
	my @return_stems;
	@return_stems = cache_lookup($word);
	if (scalar @return_stems == 0) {
		my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => $debug);
#		print STDERR "call Frontier::Client:\n";
#		print STDERR "word: $word\n";
		
		my $res = $client->call('lemma', "-LA",[$word]);
		# print STDERR "call: lemma, \"-L\",[$word]\nreturn:\n";
		# print STDERR Dumper $res;
		if (exists $res->{$word}) {
			$cache{$word} = $res->{$word};
			# print "adding word ".$word."\n";
			nstore \%cache, Files::cache_filename();
			
#			for my $key ( keys %cache ) {
#			        my $value = $cache{$key};
#			        print "$key => $value\n";
#			    }
			my $stems = $res->{$word};
			my $number_of_stems = scalar @$stems;
			foreach (@$stems) {
				push @return_stems, $_;
			}
		} 
		print STDERR "L";
	} else {
		print STDERR "C";
	}
	return @return_stems;
}


sub cache_lookup {
	my $word = shift;
	if (exists $cache{$word}) {
#		print $word." doesn't exist\n";
		my $stems = $cache{$word};
		return @$stems;
	}
#	print $word." doesn't exist\n";
	return ();
}

#----------------------------------------------------------------------#
#  FUNCTION:  hashValueAscendingNum                                    #
#                                                                      #
#  PURPOSE:   Help sort a hash by the hash 'value', not the 'key'.     #
#             Values are returned in ascending numeric order (lowest   #
#             to highest).                                             #
#----------------------------------------------------------------------#

sub hashValueAscendingNum {
   $words{$a} <=> $words{$b};
}

sub hashValueAscendingNum_stems {
   $stems{$a} <=> $stems{$b};
}


#----------------------------------------------------------------------#
#  FUNCTION:  hashValueDescendingNum                                   #
#                                                                      #
#  PURPOSE:   Help sort a hash by the hash 'value', not the 'key'.     #
#             Values are returned in descending numeric order          #
#             (highest to lowest).                                     #
#----------------------------------------------------------------------#

sub hashValueDescendingNum {
   $words{$b} <=> $words{$a};
}

sub hashValueDescendingNum_stems {
   $stems{$b} <=> $stems{$a};
}
