#!/usr/bin/env perl

=head1 NAME

cross-language-dictionary-gen.pl - create translation dictionary from parallel texts

=head1 SYNOPSIS

cross-language-dictionary-gen.pl [options] TEXT1 TEXT2

=head1 DESCRIPTION

Creates a translation dictionary in CSV format, where each line contains a stem in language 1 followed by two "translations," i.e. stems in language 2 deemed to be related to the language 1 headword.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<TEXT1>, I<TEXT2>

The parallel texts. Text 2 should be a translation of Text 1.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is cross-language-dictionary-gen.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): James Gawley

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Term::UI;
use Term::ReadLine;

use Storable qw(nstore retrieve);
use Unicode::Normalize;
use XML::LibXML;
use utf8;

# initialize some variables

my $feature = 'trans1';
my $help = 0;

# get user options

GetOptions(
	'feature=s' => \$feature,
	'help'      => \$help
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# allow utf8 debugging output

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# file to write

my $file_output = catfile($fs{data}, 'synonymy', $feature . '.csv')

open (OUTPUT, ">:utf8", $file_output) or die "$!";

##load dictionaries
my @dictionary = ();
my %la_dictionary = %{retrieve(catfile($fs{data}, 'common', "la.stem.cache"))};
my %grc_dictionary = %{retrieve(catfile($fs{data}, 'common', "grc.stem.cache"))};
# my %stem = %{retrieve("grc.stem.cache")};

my $successes;
my $failures;

#
# set up terminal interface
#

my $term = Term::ReadLine->new('myterm');

#
# read the list of files from command line
#

my @files = @ARGV;

print STDERR "checking " . scalar(@files) . " files\n";

#if a greek tag doesn't have a corresponding Latin tag, it should be deleted

#compare the length of each corresponding array and check discrepancies
#foreach my $k (sort keys %{$docs[0]}) {
#	my $val_one = @{$docs[0]{$k}};
#	my $val_two = @{$docs[1]{$k}};
#	my $div = $val_one / $val_two;
#	if (($div > 1.3) || ($div < .7)){
#		print STDERR "Apparent mismatch: \n";
#		print STDERR "$k\t" . join (" ", @{$docs[0]{$k}}) . "\n";
#		print STDERR "$k\t" . join (" ", @{$docs[1]{$k}}) . "\n";
#	}
#	
#}









#
# load each file into a hash with the tags as the keys and the sentences as the values
#

my @docs = ();
my $lang = 0;
my %greek_sentences;
my %greek_tags;
my %latin_sentences;
my %latin_tags;

for my $f (0..$#files) {

	# open the file
	
	open (my $fh, "<:utf8", $files[$f])	|| die "can't open $files[$f]: $!";

	print STDERR "reading " . ($f+1) . "/" . scalar(@files) . " $files[$f]...\n";
	$lang++;
#	my @filezors = <$fh>;
#	my $file_length = @filezors;
#	my $it = 1;
	#read each line
	while (<$fh>){
#		print STDERR "Percent complete:\t" . (($it / $file_length) * 100);
#		print STDERR "Iteration: $it";
#		$it++;
		my @array = ();
		chomp($_);
		$_ =~ /(<(.+?)>)/;
		my $key = $1;
		
		
		$_ =~ s/<(.+?)>//;
		my $tag = $1;
		
		$_ =~ s/[;.\[\],?!]//;
		$_ =~ s/\s+/ /g;
		$_ =~ s/^\s//;

		my @value = split(/ /, $_);
		my @lemmas = ();
		#Process Greek first
		if ($lang == 1){ 
			#lemmatize the words in the sentence
			@lemmas = &lemmatizeGreek(@value);
			
			#create the hash (data structure #1) containing the lemma-array, keyed by tag
			push (@{$greek_sentences{$tag}}, @lemmas);
			#Create a hash with the lemmas from @lemmas as keys (data structure #2)
			#push the current tag value to an array inside the anonymous hash at the lemma-key position
			for (0..$#lemmas){
			push (@{$greek_tags{$lemmas[$_]}}, $tag);
#			print STDERR "Lemma: $lemmas[$_]. Tag array: ";
#			print STDERR join (' ',@{$greek_tags{$lemmas[$_]}}) . "\n";	
			} #it will be necessary to check for duplicates of each tag when compiling @greek_words. 
			#Just slam them all into a hash when the time comes.


		}
		
		#Process Latin. The loop below is a repeat of the Greek loop above.
		if ($lang == 2){ 
		
			@lemmas = &lemmatizeLatin(@value);
			push (@{$latin_sentences{$tag}}, @lemmas);
			for (0..$#lemmas){
			push (@{$latin_tags{$lemmas[$_]}}, $tag);
			} 
		}
		
		
		
		

	}

}

#check for missing tags
my @greek_verse_keys = sort {$greek_sentences{$a} <=> $greek_sentences{$b}} keys(%greek_sentences);
my @latin_verse_keys = sort {$latin_sentences{$a} <=> $latin_sentences{$b}} keys(%latin_sentences);
for (0..$#greek_verse_keys) {
	my $good_match = 0;
	my $cur = $_;
	for (0..$#latin_verse_keys){
		if ($greek_verse_keys[$cur] eq $latin_verse_keys[$_]) {
			$good_match = 1;
		}
	}
	if ($good_match == 0 ) {
			print STDERR "Mismatch: " . $greek_verse_keys[$cur] . "\n"; 

	}
}

#With both data structures complete, remove all Latin lines which lack a corresponding Greek line
open (LIST, ">list_of_missing.txt") or die "$!";
foreach (keys (%latin_sentences)){ 
	if (exists ($greek_sentences{$_})){}
	else {print LIST "$_\n";
	
	delete ($latin_sentences{$_});}
}


#It's time to build the frequency table.
#I need a count of all @lemma iterations and a % keyed by lemma with a count for each 
my $tag;
my %greek_freq_hash;
my $greek_count = 0;
my @sentence;
foreach (keys %greek_sentences) {
	#First add the array of lemmas in scalar form to a word-count
	my @temp = @{$greek_sentences{$_}};

	my $size = @temp;
	$greek_count = $greek_count + $size;
#	print STDERR "Current sentence: $_\t# of words: $size\t current count: $greek_count\n";

	$tag = $_;
	@sentence = @{$greek_sentences{$_}};
	for (0..$#sentence) {
		if (exists($greek_freq_hash{$sentence[$_]})) {
		$greek_freq_hash{$sentence[$_]}++;
		}  
		else {$greek_freq_hash{$sentence[$_]} = 1;}

	}

}

#Same for Latin
my %latin_freq_hash;
my $latin_count = 0;
foreach (keys %latin_sentences) {

	#First add the array of lemmas in scalar form to a word-count
	my @temp = @{$latin_sentences{$_}};

	my $size = @temp;
	$latin_count = $latin_count + $size;

	$tag = $_;
	@sentence = @{$latin_sentences{$_}};
	for (0..$#sentence) {
		if (exists($latin_freq_hash{$sentence[$_]})) {
		$latin_freq_hash{$sentence[$_]}++;
		}  
		else {$latin_freq_hash{$sentence[$_]} = 1;}

	}

}
my @latin_stops = &genStop (%latin_freq_hash);
my @greek_stops = &genStop (%greek_freq_hash);
my %temp_hash;
#Now it is time to apply Bayes' theorem.
#For each word in the Greek hash, acquire all possible Latin translations.

#####################
my %results;
print "# of Sucesses: $successes. # of failures: $failures\n";
my $it = 1;
foreach (sort keys (%greek_tags)) {
	my @latin_results = ();
	print STDERR "Iteration $it/$greek_count:\t$_,";
	print OUTPUT "$_,";
	my $greek_key = $_;
	$it++;
	%temp_hash = &bayes ($_);
	$results{$_} = %temp_hash;
	
#find out if this is one of the 100 most common greek words:
my $grk_word = $_;
my $goflag = 1;

for (0..$#greek_stops) { if ($greek_stops[$_] eq $grk_word) {$goflag = 0;}}

my $doflag = 2;
if ($goflag == 1){
	#If the greek word is not one of the 100 most common, exclude the 100 most common Latin words:



foreach my $key (sort hashValueDescendingNum (keys(%temp_hash))) {
	my $printflag = 1;

	
	for(0..$#latin_stops){if ($key eq $latin_stops[$_]) {$printflag = 0;}}
	if ($printflag == 1){ push (@latin_results, $key);}
}
}
else {#If the greek word is common, exclude only the 5 most common Latin words:
foreach my $key (sort hashValueDescendingNum (keys(%temp_hash))) {
	my $printflag = 1;


	for(0..4){if ($key eq $latin_stops[$_]) {$printflag = 0;}}
	if ($printflag == 1){push (@latin_results, $key);}
}

}


print STDERR $latin_results[0] . "," . $latin_results[1];
print STDERR "\n";

print OUTPUT $latin_results[0] . "," . $latin_results[1];
print OUTPUT "\n";

}
########################

sub hashValueDescendingNum {
   $temp_hash{$b} <=> $temp_hash{$a};
}

sub genStop {
	my (%passed) = @_;
	my @slice;
	#choose the 100 most common words in latin and add them to a stoplist
	my @keys = sort {$passed{$b} <=> $passed{$a}} keys(%passed);
	for (0..100) {$slice[$_] = $keys[$_]}
	return @slice;

}


sub bayes {
	#Given a 'source' word, generate a set of all possible 'target' words, 
	#assess the probability of each and return them in a sorted hash of $target_lemma => $probability
	my %bayes_hash;
	my $greek_lemma = $_[0];
	my @ltn_lems;
	#I need to gather all possible target words given the greek word
	#the dereference below should create an array of sentence tags corresponding to the greek lemma
	for (0..$#{$greek_tags{$greek_lemma}}){
	my @tags = @{$greek_tags{$greek_lemma}};
	push (@ltn_lems, @{$latin_sentences{${$greek_tags{$greek_lemma}}[$_]}});

	}

	#now I should have all the latin possible lemmas, including repetitions. 
	#Merge them into a hash and generate p(g|l) 
	my %pgl;
	for (0..$#ltn_lems){
		#going through the stack of possible Latin words one by one, I have to calculate (separately)
		#the probability of the original Greek source word given this particular Latin word.
		#That means a separate iteration, and separate value, for each latin word. I cannot merge the greek words into a bag
		#for the entire array of Latin lemmas. I can make a large array of greek words for each latin lemma,
		#then go through looking for a match to the source greek word. Then I divide that by the size of the array and get p(g|l)
		my @grk_lems = ();
		my @tag_set = ();
		push (@tag_set, @{$latin_tags{$ltn_lems[$_]}});
#		print "Current latin lemma: '$ltn_lems[$_]'\nSet of related tags: " . join (' ', @tag_set);
		#WARNING: the set of tags contains unnecessary duplicates. This may throw off the math.
		for (0..$#tag_set){
#			print STDERR "\nCurrent sentence tag: $tag_set[$_]";
			push (@grk_lems, @{$greek_sentences{$tag_set[$_]}});
		}
		my $matchcount = 0;

		for (0..$#grk_lems){
			if ($grk_lems[$_] eq $greek_lemma) {$matchcount++;}
		}
		#I now have a possible latin target word, and a count of all the times the source word shows up in associated sentences,
		#so I can calculate the likelihood of the source word given the latin (p(g|l). This should be tracked for each l.
		$pgl{$ltn_lems[$_]} = ($matchcount / ($#grk_lems + 1));
		#now there's a hash variable with key: latin translation candidate & value: p(g|l)
			
	}
	#time to calculate p(g). I need to know the exact number of times the greek source word appears in the corpus 
	#and the number of words in the corpus.

	my $pg = ($greek_freq_hash{$greek_lemma} / $greek_count);
	foreach (keys %pgl) {
		my $pl = ($latin_freq_hash{$_} / $latin_count);
		$bayes_hash{$_} = ($pl * $pgl{$_} / $pg);
	}

	return (%bayes_hash);

}


sub lemmatizeLatin {
	#Takes an array of tokens and returns an array of lemmas
	my @tokens = @_;
	my @lemmas;
	for (0..$#tokens){
	my $tok = $tokens[$_];	
	my $lem;
	$lem = ${$la_dictionary{$tok}}[0];
	if (defined ($lem)){}
	else {
	$lem = $tok;
	}
	push (@lemmas, $lem);		
	}
	return (@lemmas);
}

sub lemmatizeGreek {
	#Takes an array of tokens and returns an array of lemmas
	my @tokens = @_;
	

	my @lemmas;
	for (0..$#tokens){
	my $tok = standardize($tokens[$_]);	
#	print STDERR "The 'Greek' subroutine has been passed: $tok;\n";
	my $lem;
	$lem = ${$grc_dictionary{$tok}}[0];
	
	#Use the token itself if it can't be lemmatized.
	if (defined($lem)){$successes++;}
	else {
	$failures++;
	$lem = $tok;
	}
#	print STDERR "The 'Greek' subroutine has returned: $lem;\n";
#	my $useless = <STDIN>;
	
	#Now add the lemma to the array to be returned
	push (@lemmas, $lem);
	}
	return (@lemmas);
}

# sub stemmer {
# 
# 	my $form = shift;
# 	print STDERR "Stemmer has received: $form";
# 	my $useless = <STDIN>;
# 	my @stems;
# 	
# 
# 	if (defined $stem{$form}) {
# 	print STDERR "The 'stems' subroutine has been passed: $form\n";
# 		@stems = @{$stem{$form}};
# 		print STDERR "The dictionary has returned: $stems[0]\n";
# 			my $useless = <STDIN>;
# 	}
# 	else {
# 		print STDERR "unlemmatized form $form\n";
# 		push @stems, $form;
# 			my $useless = <STDIN>;
# 	}
# 	
# 	return $stems[0];
# }

#
# standardize input for compatibility with hash keys
#

sub standardize {

	my $token = shift;
	
	# normalize to decomposed diacritics
	
	$token = NFKD($token);
	
	# lowercase
	
	$token = lc($token);
	
	# replace latin j and v with i and u
	
	$token =~ tr/jv/iu/;
		
	# move initial diacritics to the right of following vowel
	
	$token =~ s/([\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]+)([αειηουωΑΕΙΗΟΥΩ])/$2$1/;
		
	# change grave accent (context-specific) to acute (dictionary form)
			
	$token =~ s/\x{0300}/\x{0301}/g;
			
	# remove non-word chars
			
	$token =~ s/\W//g;

	return $token;
}



sub buildFrequencies {
	#This subroutine builds a hash of all lemmas and associates a frequency score.
	#Frequency of a word is a substitute for Bayes' p(e) or p(f) (probability of word)

}