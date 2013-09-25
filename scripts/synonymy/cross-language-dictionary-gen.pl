#!/usr/bin/env perl

=head1 NAME

cross-language-dictionary-gen.pl - create translation dictionary from parallel texts

=head1 SYNOPSIS

cross-language-dictionary-gen.pl [options] --grc TEXT1 --la TEXT2

=head1 DESCRIPTION

Creates a translation dictionary in CSV format, where each line contains a stem in language 1 followed by two "translations," i.e. stems in language 2 deemed to be related to the language 1 headword.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--grc> I<TEXT1>

The Greek text.

=item B<--la> I<TEXT2>

The Latin text.

=item B<--feature> I<FEATURE>

The name of the dictionary, which will be saved as 'data/synonymy/FEATURE.csv' Default is 'trans1'.

=item B<--help>

Print usage and exit.

=item B<--quiet>

Don't print debugging info to the terminal.

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

Contributor(s): James Gawley, Chris Forstall

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
use utf8;

# initialize some variables

my %file        = ('la' => undef, 'grc' => undef);
my $feature     = 'trans1';
my $help        = 0;
my $quiet       = 0;
my $max_results = 2;

# get user options

GetOptions(
	'feature=s' => \$feature,
	'la=s'      => \$file{la},
	'grc=s'     => \$file{grc},
	'n=i'       => \$max_results,
	'quiet'     => \$quiet,
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

my $file_output = catfile($fs{data}, 'synonymy', $feature . '.csv');

open (OUTPUT, ">:utf8", $file_output) or die "Can't write $file_output: $!";

# make sure both inputs exist

for my $lang (keys %file) {

	unless (defined $file{$lang}) {
		
		warn "One or more input documents was unspecified.";
		pod2usage(1);
	}
	
	unless (-e $file{$lang}) {
	
		die "Document $file{$lang} doesn't exist.\n";
	}
}

# counts for successes and failures

my $successes;
my $failures;

#
# load each file into a hash with the tags as the keys and the sentences as the values
#

my %sentences;
my %tags;

for my $lang (keys %file) {

	# open the file
	
	open (my $fh, "<:utf8", $file{$lang}) or die "Can't open $file{$lang}: $!";

	print STDERR "Reading $lang document $file{$lang}...\n" unless $quiet;

	my $pr = ProgressBar->new(-s $file{$lang}, $quiet);

	# read each line

	while (my $line = <$fh>) {
		
		$pr->advance(length(Encode::encode('utf8', $line)));
		
		my @array = ();

		chomp($line);
				
		$line =~ s/<(.+?)>//;
		my $tag = $1;
		
		my @tokens = split(/$non_word{$lang}/, $line);

		@tokens = Tesserae::standardize($lang, @tokens);
		
		my @lemmas = @{Tesserae::feat($lang, 'stem', \@tokens, force=>1)};

		#create the hash (data structure #1) containing the lemma-array, keyed by tag

		push @{$sentences{$lang}{$tag}}, @lemmas;
		
		#Create a hash with the lemmas from @lemmas as keys (data structure #2)
		#push the current tag value to an array inside the anonymous hash at the lemma-key position
		
		for my $l (@lemmas) {
		
			push(@{$tags{$lang}{$l}}, $tag);
		}
		
		#it will be necessary to check for duplicates of each tag when compiling @greek_words. 
		#Just slam them all into a hash when the time comes.
	}
}


#check for missing tags

my %exists;
my $both = join("", sort keys %sentences);

for my $lang (sort keys %sentences) {

	for my $tag (keys %{$sentences{$lang}}) {
	
		$exists{$tag} .= $lang;
	}
}

# delete lines that don't have a match in the other language

for my $tag (sort keys %exists) {

	unless ($exists{$tag} eq $both) {
		
		print STDERR "Mismatch: $tag exists only in $exists{$tag}! Deleting.\n" unless $quiet;

		delete $sentences{$exists{$tag}}{$tag};
		$exists{$tag} = 0;
	}
}

print STDERR "Purging non-existent tags\n" unless $quiet;

for my $lang (sort keys %sentences) {

	for my $lemma (keys %{$tags{$lang}}) {
	
		$tags{$lang}{$lemma} = [grep {$exists{$_}} @{$tags{$lang}{$lemma}}];
	}
}


#It's time to build the frequency table.
#I need a count of all @lemma iterations and a % keyed by lemma with a count for each 

print STDERR "Building frequency tables\n" unless $quiet;

my %freq_hash;
my %word_count;
my %stops;

for my $lang (keys %sentences) {

	for my $tag (keys %{$sentences{$lang}}) {

		my @sentence = @{$sentences{$lang}{$tag}};
	
		#First add the array of lemmas in scalar form to a word-count
		$word_count{$lang} += scalar(@sentence);
	
		# increment freq count for each lemma
		for my $lemma (@sentence) {
		
			$freq_hash{$lang}{$lemma}++;
		}
	}
	
	$stops{$lang} = genStop($freq_hash{$lang});
}

#Now it is time to apply Bayes' theorem.
#For each word in the Greek hash, acquire all possible Latin translations.

#####################

print STDERR "Applying Bayes' theorem\n";

my $it = 0;

foreach my $greek_key (keys %{$tags{grc}}) {
	
	$it++;
	
	my @latin_results = ();
	
	print STDERR "Iteration $it/$word_count{grc}:" unless $quiet;

	my %results = %{bayes($greek_key)};
	
	#If the greek word is common, exclude only the 5 most common Latin words;
	# otherwise, exclude the full stoplist of 100
	
	my $stoplist_size = 100;
	
	if (grep { $_ eq $greek_key } @{$stops{grc}}) {
		
		$stoplist_size = 5;
	}
		
	# check results in descending order against the stoplist
		
	foreach my $latin_key (sort {$results{$b} <=> $results{$a}} keys(%results)) {
			
		next if grep {$_ eq $latin_key} @{$stops{la}}[0..$stoplist_size-1];

		push (@latin_results, $latin_key);
		
		last if scalar(@latin_results) == $max_results;
	}

	my $row = join(",", $greek_key, @latin_results) . "\n";

	print STDERR $row unless $quiet;
	print OUTPUT $row;
}


sub genStop {
	my $href = shift;
	my %passed = %$href;
	
	#choose the 100 most common words in latin and add them to a stoplist
	
	my @keys = sort {$passed{$b} <=> $passed{$a}} keys(%passed);

	my @slice = @keys[0..99];

	return \@slice;
}


sub bayes {
	#Given a 'source' word, generate a set of all possible 'target' words, 
	#assess the probability of each and return them in a sorted hash of $target_lemma => $probability

	my %bayes_hash;
	my $greek_lemma = shift;
	my @ltn_lems;
	
	#I need to gather all possible target words given the greek word
	#the dereference below should create an array of sentence tags corresponding to the greek lemma
	for my $tag (@{$tags{grc}{$greek_lemma}}) {
		
		unless (defined $sentences{la}{$tag}) {
			print STDERR "bayes: $tag doesn't exist in Latin index! (key=$greek_lemma)\n";
		}
		
		push (@ltn_lems, @{$sentences{la}{$tag}});
	}

	#now I should have all the latin possible lemmas, including repetitions. 
	#Merge them into a hash and generate p(g|l)
	my %pgl;
	
	for my $latin_lemma (@{Tesserae::uniq(\@ltn_lems)}) {
		#going through the stack of possible Latin words one by one, I have to calculate (separately)
		#the probability of the original Greek source word given this particular Latin word.
		#That means a separate iteration, and separate value, for each latin word. I cannot merge the greek words into a bag
		#for the entire array of Latin lemmas. I can make a large array of greek words for each latin lemma,
		#then go through looking for a match to the source greek word. Then I divide that by the size of the array and get p(g|l)
		
		my @grk_lems = ();

		for my $tag (@{$tags{la}{$latin_lemma}}) {

			push (@grk_lems, @{$sentences{grc}{$tag}});
		}
		
		my $matchcount = 0;

		for (0..$#grk_lems) {
			
			if ($grk_lems[$_] eq $greek_lemma) {$matchcount++;}
		}
		
		#I now have a possible latin target word, and a count of all the times the source word shows up in associated sentences,
		#so I can calculate the likelihood of the source word given the latin (p(g|l). This should be tracked for each l.
		$pgl{$latin_lemma} = ($matchcount / ($#grk_lems + 1));
		
		#now there's a hash variable with key: latin translation candidate & value: p(g|l)
	}
	#time to calculate p(g). I need to know the exact number of times the greek source word appears in the corpus 
	#and the number of words in the corpus.

	my $pg = ($freq_hash{grc}{$greek_lemma} / $word_count{grc});
	
	foreach (keys %pgl) {
		
		my $pl = ($freq_hash{la}{$_} / $word_count{la});
		$bayes_hash{$_} = ($pl * $pgl{$_} / $pg);
	}

	return (\%bayes_hash);
}

