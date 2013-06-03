#! /usr/bin/perl

# add_column.pl
#
# add a new text to the database

=head1 NAME

add_column.pl	- add texts to the tesserae database

=head1 SYNOPSIS

perl add_column.pl [options] TEXT [, TEXT2, [DIR], ...] 

=head1 DESCRIPTION

Reads in one or more .tess documents and creates the indices used by read_table.pl
to perform Tesserae searches.

This script is usually run on an entire directory of texts at once, when you're
first setting Tesserae up.  E.g. (from the Tesserae root dir),

   perl scripts/v3/add_column.pl texts/la/*

If the script is passed a directory instead of a file, it will search inside for
.tess files; this is designed for works which have been partitioned into separate
files, e.g. by internal "book".  These .part. files are stored inside a directory
named for the original work.

If you have a file in the I<texts/> directory called I<prose_list>, this will be
read and any texts whose names are found in the prose list will be added to the
database in "prose mode".  Because the "line" unit of text doesn't make much sense
for prose works, in prose mode the line database is just a copy of the phrase one.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang>

Specify the language code for all texts.  By default tries to guess from the
path, which usually includes this code.  Tells Tesserae where to look for 
stem dictionaries, etc.

=item B<--parllel N>

Allow up to N processes to run in parallel.  Requires Parallel::ForkManager.

=item B<--use-lingua-stem>

Use the Lingua::Stem module to do stemming instead of internal dictionaries.
This is the only way to index English works by stem; I don't think it works
for Latin and almost certainly not for Greek.  The language code will be 
passed to Lingua::Stem, which must have a stemmer for that code.

=item B<--prose>

Force all texts to be added in prose mode.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is add_column.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall <forstall@buffalo.edu>, James Gawley, Neil Coffee

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
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use utf8;
use File::Path qw(mkpath rmtree);
use File::Basename;
use Storable qw(nstore retrieve);
use Encode;

# optional modules

my $override_stemmer  = Tesserae::check_mod("Lingua::Stem");
my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

#
# splitting phrases
#

# a complicated regex to test for their presence
# if you match this $1 and $2 will be set to the parts
# belonging to the left and right phrases respectively

my $split_punct = qr/(.*"?$phrase_delimiter"?)(\s*)(.*)/;

# 
# initialize some parameters
# 

my %abbr;
my $file_abbr = catfile($fs{data},'common', 'abbr');
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

# these are for optional use of Lingua::Stem

my $use_lingua_stem = 0;
my $stemmer;

#
# for parallel processing
#

my $max_processes = 0;
my $pm;

#
# declare language tools
#

my $lang;
my %stem;
my %syn;

# don't print messages to STDERR 
my $quiet = 0;

# print usage and exit
my $help = 0;

# flag work as prose (not used yet)
my $prose = 0;

# allow utf8 output to stderr
binmode STDERR, ':utf8';

#
# command line options
#

GetOptions( 
	"lang=s"          => \$lang,
	"parallel=i"      => \$max_processes,
	"quiet"           => \$quiet,
	"prose"           => \$prose,
	"use-lingua-stem" => \$use_lingua_stem,
	"help"            => \$help
	);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# check to make sure stemmer module is available

if ($use_lingua_stem and $override_stemmer) {

	print STDERR 
		"Lingua::Stem was not installed when you configured Tesserae.  "
	   . "If you have installed it since then, please re-configure.  "
	   . "Falling back on stem dictionary method for now.\n";
	   
	$use_lingua_stem = 0;
}

#
# initialize parallel processing
#

if ($max_processes and $override_parallel) {

	print STDERR "Parallel processing requires Parallel::ForkManager from CPAN.\n";
	print STDERR "Proceeding with parallel=0.\n";
	$max_processes = 0;

}

if ($max_processes) {

	$pm = Parallel::ForkManager->new($max_processes);
}

#
# create a temp file to gather language info 
# generated by child processes
#

my $temp_dir = catdir($fs{data}, 'common', 'temp-lang');
if (-d $temp_dir) {

	print STDERR "$temp_dir exists!  Is someone else running add_column?\n";
	print STDERR "If not, please delete $temp_dir manually and try again.\n";
	exit;
}

mkpath($temp_dir);

#
# get files to be processed from cmd line args
#

my @files = map { glob } @ARGV;

for my $file_in (@files) {
	
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if (-d $file_in) {

		opendir (DH, $file_in);

		my @parts = (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

		push @files, @parts;
					
		closedir (DH);
		
		# move on to the next full text

		next;
	}
	
	my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
	next unless ($suffix eq ".tess");
		
	# get the language for this doc.  try:
	# 1. user specified at cmd line
	# 2. cached from a previous successful parse
	# 3. somewhere in the path to the text
	# - then give up

	if ( defined $lang and $lang ne "") {
	}
	elsif ( defined Tesserae::lang($name) ) {

		$lang = Tesserae::lang($name);
	}
	elsif (Cwd::abs_path($file_in) =~ m/$fs{text}\/([a-z]{1,4})\//) {

		$lang = $1;
	}
	else {

		print STDERR "Can't guess the language of $file_in! "
					. "Try reprocessing with --lang LANG\n" unless $quiet;
		next;
	}
	
	#
	# check prose list
	#
	
	my $prose = $prose || Tesserae::check_prose_list($name);
		
	#
	# fork
	#
	
	if ($max_processes) {

		$pm->start and next;
	}
	
	#
	# initialize variables
	#
	
	my @token;
	my @line;
	my @phrase = ({});

	my %ref;

	my %index;

	#
	# check for the dictionaries
	#
		
	my $file_stem = catfile($fs{data}, 'common', "$lang.stem.cache");
	my $file_syn  = catfile($fs{data}, 'common', "$lang.syn.cache");
	
	my %omit;
	
	if (-r $file_stem or $use_lingua_stem) {
			
		if ($use_lingua_stem) {
		
			$stemmer = Lingua::Stem->new({-locale => $lang});
		}
		else {
		
			%stem = %{ retrieve($file_stem) };
		}
		
		if (-r $file_syn) {
	
			%syn = %{ retrieve($file_syn) };
		}
		else {
			
			print STDERR "Can't find syn dictionary! "
						. "Syn indexing disabled.\n" unless $quiet;
			$omit{syn} = 1;
		}
	}
	else {
		
		print STDERR "Can't find stem dictionary! "
					 . "Stem and syn indexing disabled.\n" unless $quiet;
		$omit{stem} = 1;
		$omit{syn}  = 1;
	}
	
	#
	# assume unknown lang is like english
	#
	
	unless (defined $is_word{$lang})  { $is_word{$lang}  = $is_word{en} }
	unless (defined $non_word{$lang}) { $non_word{$lang} = $non_word{en} }

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words

	print STDERR "reading text: $file_in\n" unless $quiet;

	# open the input text

	open (TEXT, "<:utf8", $file_in) or die("Can't open file ".$file_in);

	# assume first quote mark is a left one
	
	my $toggle = 1;

	# examine each line of the input text

	while (my $l = <TEXT>) {
		
		chomp $l;

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001>	this is a verse

		$l =~ /^\S*<(.+)>\s+(.+)/;
		
		my ($locus, $verse) = ($1, $2);

		# skip lines with no locus or line

		next unless (defined $locus and defined $verse);
		
		# start a new line
		
		push @line, {};

		# examine the locus of each line

		$locus =~ s/^(.*)\s//;
		
		# save the abbreviation of the author/work
		
		$ref{$1}++;

		# save the book/poem/line number

		$line[-1]{LOCUS} = $locus;

		# remove html special chars

		$verse =~ s/&[a-z];//ig;
		$verse =~ s/[<>]//g;

		#
		# check for enjambement with prev line
		#
		
		if (defined $phrase[-1]{TOKEN_ID}) {

			push @token, {TYPE => 'PUNCT', DISPLAY => ' / '};
			push @{$phrase[-1]{TOKEN_ID}}, $#token;
		}
		
		# split the line into tokens				
		# add tokens to the current phrase, line

		while (length($verse) > 0) {
			
			#
			# add word token
			#
			
			if ( $verse =~ s/^($is_word{$lang})// ) {
			
				my $token = $1;
			
				# this display form
				# -- just as it appears in the text

				my $display = $token;
				
				#
				# an experimental feature
				#
				
				if ($token =~ /TESSFORM(.+?)TESSDISPLAY(.+?)/) {
				
					($token, $display) = ($1, $2);
				}

				# convert display greek to unicode

				if ($lang eq "grc") {

					$display = Tesserae::beta_to_uni($display);
				}

				# the searchable form 
				# -- flatten orthographic variation

				my $form = Tesserae::standardize($lang, $token);

				# add the token to the master list

				push @token, { 
					TYPE => 'WORD',
					DISPLAY => $display, 
					FORM => $form ,
					LINE_ID => $#line,
					PHRASE_ID => $#phrase
				};

				# add token id to the line and phrase

				push @{$line[-1]{TOKEN_ID}}, $#token;
				push @{$phrase[-1]{TOKEN_ID}}, $#token;

				# note that this phrase extends over this line

				$phrase[-1]{LINE_ID}{$#line} = 1;
				
				#
				# index
				#
				
				# by form
				
				push @{$index{word}{$form}}, $#token;
				
				# by stem
				
				unless ($omit{stem}) {
				
					for my $stem (@{stems($form)}) {
					
						push @{$index{stem}{$stem}}, $#token;
					}
				}
				
				# by syn
				
				unless ($omit{syn}) {
								
					for my $syn (@{syns($form)}) {
					
						push @{$index{syn}{$syn}}, $#token;
					}
				}
				
				# by chr 3-grams
				
				my $alpha = Tesserae::alpha($lang, $form);
								
				for my $ngram (@{chr_ngrams(3, $alpha)}) {
								
					push @{$index{"3gr"}{$ngram}}, $#token;
				}				
			}

			#
			# add punct token
			#
			
			elsif ( $verse =~ s/^($non_word{$lang})// ) {
			
				my $token = $1;
				
				# tidy up double quotation marks
				
				while ($token =~ /"/) {

					my $quote = $toggle ? '“' : '”';

					$token =~ s/"/$quote/;

					$toggle = ! $toggle;
				}
			
				# check for phrase-delimiting punctuation
				#
				# if we find any, then this token should
				# be split into two, so that one part can
				# go with each phrase.

				if ($token =~ $split_punct) {

					my ($left, $space, $right) = ($1, $2, $3);

					push @token, {TYPE => 'PUNCT', DISPLAY => $left};

					push @{$line[-1]{TOKEN_ID}}, $#token;
					push @{$phrase[-1]{TOKEN_ID}}, $#token;

					# add intervening white space to the line,
					# but not to either phrase

					if ($space ne '') {

						push @token, {TYPE => 'PUNCT', DISPLAY => $space};
						push @{$line[-1]{TOKEN_ID}}, $#token;
					}

					# start a new phrase

					push @phrase, {};
					
					# now let the body of the function handle what remains

					$token = $right;
				}

				# skip empty strings

				if ($token ne '') {

					# add to the current phrase, line

					push @token, {TYPE => 'PUNCT', DISPLAY => $token};

					push @{$line[-1]{TOKEN_ID}}, $#token;
					push @{$phrase[-1]{TOKEN_ID}}, $#token;
				}
			}
			else {
				
				warn "Can't parse <<$l>> on $file_in line $.. Skipping.";
				next;
			}			
		}
	}
	
	# if the poem ends with a phrase-delimiting punct token,
	# there will be an empty final phrase;
	# if the poem ends with the sequence ." you can end up
	# with a final phrase composed of " alone.  Check for
	# these and delete
	
	my $haswords = 0;
	
	for (@{$phrase[-1]{TOKEN_ID}}) {
	
		if ($token[$_]{TYPE} eq 'WORD') {
		
			$haswords = 1;
			last;
		}
	}
	
	unless ($haswords) {
	
		push @{$phrase[-2]{TOKEN_ID}}, @{$phrase[-1]{TOKEN_ID}};
	
		pop @phrase;
	}
	
	#
	# tidy up relationship between phrases and lines:
	#  - convert the LINE_ID tag of phrases to a simple array
	#
		
	for my $phrase_id (0..$#phrase) { 
		
		$phrase[$phrase_id]{LINE_ID} = [sort {$a <=> $b} keys %{$phrase[$phrase_id]{LINE_ID}} ];

		# if there's a range, just use the first line
			
		$phrase[$phrase_id]{LOCUS} = $line[$phrase[$phrase_id]{LINE_ID}[0]]{LOCUS};
	}
		
	#
	# save the data
	#
	
	# make sure the directory exists
	
	my $path_data = catfile($fs{data}, 'v3', $lang, $name);
	
	unless (-d $path_data ) { mkpath($path_data) }
	
	my $file_out = catfile($path_data, $name);

	print STDERR "writing $file_out.token\n" unless $quiet;
	nstore \@token, "$file_out.token";

	print STDERR "writing $file_out.line\n" unless $quiet;
	nstore \@line, "$file_out.line";
	
	print STDERR "writing $file_out.phrase\n" unless $quiet;
	nstore \@phrase, "$file_out.phrase";

	for (qw/word stem syn 3gr/) {
	
		next if $omit{$_};

		print STDERR "writing $file_out.index_$_\n" unless $quiet;
		nstore $index{$_}, "$file_out.index_$_";
		
		# calculate frequencies for stop and score
				
		print STDERR "writing $file_out.freq_stop_$_\n" unless $quiet;
		write_freq_stop($index{$_}, "$file_out.freq_stop_$_");

		print STDERR "writing $file_out.freq_score_$_\n" unless $quiet;
		write_freq_score($_, $index{word}, "$file_out.freq_score_$_");
	}

	# add this ref to the database of abbreviations

	my $abbr = (sort { $ref{$b} <=> $ref{$a} } keys %ref)[0];
	
	my $temp_file = catfile($temp_dir, $name . ".abbr");

	if (open (LAFH, ">:utf8", $temp_file)) {
	
		print LAFH "$abbr\n";
		close LAFH;
	}
	else {
	
		warn "can't write to $temp_file; language info for $name won't be remembered.";
	}

	# save the language designation for this file

	$temp_file = catfile($temp_dir, $name . ".lang");

	if (open (LAFH, ">:utf8", $temp_file)){
	
		print LAFH "$lang\n";
		close LAFH;
	}
	else {
	
		warn "can't write to $temp_file; language info for $name won't be remembered.";
	}
	
	$pm->finish if $max_processes;
}

$pm->wait_all_children if $max_processes;

#
# get all the language info
#

opendir(DH, $temp_dir);

my @names = grep {/\.lang$/} readdir(DH);

for (@names) {

	open (LAFH, "<", catfile($temp_dir, $_)) or next;
	
	my $lang = <LAFH>;
	
	chomp $lang;
	
	s/\.lang$//;
	
	# save to database
	
	Tesserae::lang($_, $lang);
	
	close LAFH;
}

closedir(DH);

opendir(DH, $temp_dir);

@names = grep {/\.abbr$/} readdir(DH);

for (@names) {

	open (LAFH, "<", catfile($temp_dir, $_)) or next;
	
	my $abbr = <LAFH>;
	
	chomp $abbr;

	s/\.abbr$//;
	
	$abbr{$_} = $abbr;
	
	close LAFH;
}

closedir(DH);

# save

nstore \%abbr, $file_abbr;

# clean up temp dir

rmtree($temp_dir);

#
# subroutines
#

# this sub writes a sorted list of features and their frequencies
# suitable for creating a stoplist.  frequencies are for features
# not words; since (for some feature sets anyway) words may have
# more than one feature, the count of all features in the text can
# exceed the count of all words.

sub write_freq_stop {
	
	my ($index_ref, $file) = @_;
	
	my %index = %$index_ref;
	
	my %count;
	
	my $total = 0;
	
	for (keys %index) {
		
		$count{$_} = scalar(@{$index{$_}});
		$total   += $count{$_};
	}
	
	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count{$b} <=> $count{$a}} keys %count) {
		
		print FREQ sprintf("%s\t%i\n", $_, $count{$_});
	}
	
	close FREQ;
}

#
# this sub creates a list of words and their feature-based
# frequencies suitable for the scoring algorithms.
#
# although frequencies are based on the counts of features,
# they are given for individual inflected words.  There are
# some problems with this implementation, but this seems to
# work pretty well compared to the alternatives.
#

sub write_freq_score {

	my ($feature, $index_ref, $file) = @_;

	# word-freq is the same as for the stop list
	
	if ($feature eq 'word') {
	
		return write_freq_stop($index_ref, $file);
	}

	# otherwise, proceed
	
	my %index = %$index_ref;
		
	my %by_feature;
	my %count_by_word;
	my $total;

	# count and index words by feature
	
	for my $word (keys %index) {

		$count_by_word{$word} += scalar(@{$index{$word}});
		
		$total += $count_by_word{$word};
		
		my @indexable;
		
		if    ($feature eq 'stem') { @indexable = @{stems($word)} }
		elsif ($feature eq 'syn' ) { @indexable = @{syns($word)}  }
		elsif ($feature eq '3gr' ) { @indexable = @{chr_ngrams(3, Tesserae::alpha($lang, $word))}  }
		else                       { return {} }
		
		for my $key (@indexable) {
		
			push @{$by_feature{$key}}, $word;
		}
	}
	
	#
	# calculate the stem-based count
	#
	
	my %count_by_feature;
	
	for my $word1 (keys %count_by_word) {
	
		# this is to remember what we've
		# counted once already.
		
		my %already_seen;
		
		my @indexable;
		
		if    ($feature eq 'stem') { @indexable = @{stems($word1)} }
		elsif ($feature eq 'syn' ) { @indexable = @{syns($word1)}  }
		elsif ($feature eq '3gr' ) { @indexable = @{chr_ngrams(3, Tesserae::alpha($lang, $word1))}  }
						
		# for each of its indexable features
		
		for my $key (@indexable) {
			
			# count each of the words 
			# with which it shares that stem
			
			for my $word2 (@{$by_feature{$key}}) {
				
				next if $already_seen{$word2};
				
				$count_by_feature{$word1} += $count_by_word{$word2};
				
				$already_seen{$word2} = 1;
			}
		}
	}
	
	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count_by_feature{$b} <=> $count_by_feature{$a}} keys %count_by_feature) { 
	
		print FREQ sprintf("%s\t%i\n", $_, $count_by_feature{$_});
	}
	
	close FREQ;
}

sub stems {

	my $form = shift;
	
	my @stems;
	
	if ($use_lingua_stem) {
	
		@stems = @{$stemmer->stem($form)};
	}
	elsif (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}

sub syns {

	my $form = shift;
	
	my %syns;
	
	for my $stem (@{stems($form)}) {
	
		if (defined $syn{$stem}) {
		
			for (@{$syn{$stem}}) {
			
				$syns{$_} = 1;
			}
		}
	}
	
	return [keys %syns];
}

sub chr_ngrams {

	my ($n, $form) = @_;
	
	my %ngrams;
	
	if (length($form) >= $n) {
	
		for (my $i = 0; $i < length($form) - $n + 1; $i++) {
		
			$ngrams{substr($form, $i, 3)} = 1;
		}
	}
	
	return [keys %ngrams];
}

