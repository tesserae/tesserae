# check-phrase.pl
# 
# This script is supposed to read a set of benchmark, hand-graded allusions
# from a CSV file and correlate the phrases referenced with phrases in our
# Tesserae database. 
#
# It's not checking the benchmark set against Tesserae results, it's just 
# making sure that we can actually find the phrase pairs in our texts.
#
# The script writes a binary version of the benchmark database, in which
# it replaces the original text of the two phrases with the equivalent 
# text from Tesserae.  It's saved to data/rec.cache.
#
# Chris Forstall
# 2011-12-08
#
# rev. 2012-06-12

use strict;
use warnings;

use Data::Dumper;
use Storable qw(nstore retrieve);

# lowest similarity accaptable without remark

my $warn_threshold = .4;

# location of the data

my $fs_data = "/Users/chris/Sites/tesserae/data";

my %file = (
	
	lucan_word          => "$fs_data/v3/la/word/lucan.pharsalia.part.1.word",
	lucan_phrase        => "$fs_data/v3/la/word/lucan.pharsalia.part.1.phrase",
	lucan_loc_phrase    => "$fs_data/v3/la/word/lucan.pharsalia.part.1.loc_phrase",
	lucan_loc_line      => "$fs_data/v3/la/word/lucan.pharsalia.part.1.loc_line",
	lucan_phrase_lines  => "$fs_data/v3/la/word/lucan.pharsalia.part.1.phrase_lines",
	
	vergil_word         => "$fs_data/v3/la/word/vergil.aeneid.word",
	vergil_phrase       => "$fs_data/v3/la/word/vergil.aeneid.phrase",
	vergil_loc_phrase   => "$fs_data/v3/la/word/vergil.aeneid.loc_phrase",
	vergil_loc_line     => "$fs_data/v3/la/word/vergil.aeneid.loc_line",
	vergil_phrase_lines => "$fs_data/v3/la/word/vergil.aeneid.phrase_lines",
	
	benchmark => "bench.csv"
);

# load the data

my %phrase;
my %loc_phrase;
my %loc_line;
my %phrase_lines;
my %phrase_index;

for my $text ('lucan', 'vergil')
{

	#
	# load tesserae structures
	#
	
	@{$phrase{$text}} 		= @{ retrieve($file{$text. "_phrase"})      };
	@{$loc_phrase{$text}} 	= @{ retrieve($file{$text. "_loc_phrase"})  };
	@{$loc_line{$text}} 		= @{ retrieve($file{$text. "_loc_line"})    };
	@{$phrase_lines{$text}}	= @{ retrieve($file{$text. "_phrase_lines"})};

	#
	# simplify the tesserae @phrase arrays to simple arrays of words
	#
	
	# get the word list for this text

	my @word = @{ retrieve($file{$text. "_word"}) };
	
	# convert word indices to words
	
	for (@{$phrase{$text}}) {
	
		my $phrase = $_;
	
		my @words;
		
		for my $wi (@{$$phrase{WORD}}) {
		
			push @words, $word[$wi];
		}
		
		$_ = [@words];
	}

	# index the phrases
	# 
	#  for a given line number, an array of phrases which include
	# any part of that line.

	for my $phrase_id (0..$#{$phrase_lines{$text}})
	{
		for my $line_id (@{$phrase_lines{$text}[$phrase_id]}) {
			
			push @{$phrase_index{$text}{$loc_line{$text}[$line_id]}}, $phrase_id;
		}
	}
}

# load the csv file

my @rec = @{ LoadCSV($file{benchmark}) };

# confirm that everything worked

print STDERR "lucan has " . scalar(@{$phrase{'lucan'}}) . " phrases\n";
print STDERR "vergil has " . scalar(@{$phrase{'vergil'}}) . " phrases\n";
print STDERR "the csv file contains " . scalar(@rec) . " records\n\n";

print STDERR "aligning records\n";


#
# match up each record with a parsed phrase 
#

for my $rec_index (0..$#rec) {	

	for my $text ('lucan', 'vergil') {
		
		my $pref = ( $text eq 'lucan' ? 'BC' : 'AEN' );
	
		# get the locus and the corresponding index
		# for the array containing the text
	
		my $bn = $rec[$rec_index]{$pref . '_BOOK'};
		my $ln = $rec[$rec_index]{$pref . '_LINE'};
		
		if (! defined $phrase_index{$text}{"$bn.$ln"} ) { die "$text $bn.$ln has no entry in phrase_index" }
		
		my @phrase_index = @{$phrase_index{$text}{"$bn.$ln"}};
			
		# get the phrase from the CSV file
	
	 	my $search = $rec[$rec_index]{$pref . '_TXT'};
	
		# do the search
		
		my ($decided, $max) = Align($search, $text, \@phrase_index);
		
		# if the results are really bad, check for a missing zero in the line number
		
		if ($max <= .3) {
			
			if (length($ln) < 3 && defined $phrase_index{$text}{"$bn.${ln}0"}) {
				
				# print STDERR "checking lost trailing zeros\n";
				
				push @phrase_index, @{$phrase_index{$text}{"$bn.${ln}0"}};
				
				if (length($ln) < 2 && defined $phrase_index{$text}{"$bn.${ln}00"}) { 
					
					push @phrase_index, @{$phrase_index{$text}{"$bn.${ln}00"}} ;
				}
				
				($decided, $max) = Align($search, $text, \@phrase_index);
			}
		}
		
		if ($max <= $warn_threshold) {
		
			print STDERR "$text $bn.$ln : $search\n";
			print STDERR " $max\t$decided\t$loc_phrase{$text}[$decided]\t" . join(" ", @{$phrase{$text}[$decided]}) . "\n";
					
		}
		
#		print STDERR "decided $decided by $max\n";
				
		$rec[$rec_index]{$pref . '_PHRASE'} = [@{$phrase{$text}[$decided]}];
	}
}

nstore \@rec, 'data/rec.cache';



# this subroutine reads a .tess file specified as the first arg
# and returns three references:
#  - an index hash, where keys are book.line refs and values are ints
#  - a loc array, storing "book.line" refs
#  - a txt array, storing the lines of the poem
# the values of the index hash are the indices of the corresponding
# lines in the two arrays.

# the first arg is the file name to read
# the second arg is the string preceding the book.line ref in the locus

sub LoadTess {
	
	my ($file, $string) = @_;
	
	my %index;
	my @loc;
	my @txt;
	
	open FH, "<$file" || die "can't open $file: $!";

	while (my $line = <FH>) {
		
		chomp $line;
	
		next unless ($line =~ /<$string (\d+\.\d+)>\t(.+)/);
	
		push @loc, $1;
		push @txt, $2;
		$index{$1} = $#loc;
	}

	close FH;

	return (\%index, \@loc, \@txt);
}

# this subroutine reads the CSV file containing hand-graded allusions
#

sub LoadCSV {
	
	my $file = shift;
	
	my @rec;

	open FH, "<$file" || die "can't open $file: $!";
	
	# skip the header
	
	<FH>;
	
	while (my $line = <FH>) {
		
		chomp $line;
		
		my @field = split(/,/, $line);
		
		next unless ($#field == 6);
		
		for (@field) {
			
			s/^"(.*)"$/$1/;
		}

		push @rec, {
			BC_BOOK	=> $field[0],
			BC_LINE	=>	$field[1],
			BC_TXT	=>	$field[2],
			AEN_BOOK	=>	$field[3],
			AEN_LINE	=> $field[4],
			AEN_TXT	=> $field[5],
			SCORE 	=> $field[6] 
			};
	}
	
	return \@rec;
	
	close FH;
}

# this takes a string of text and turns it into an array
# of lower-case words, stripping non-letter chars

sub Clean {
	
	my $string = shift;
	
	$string = lc($string);
	$string =~ tr/jv/iu/;
	
	my @array = split(/[^a-z]+/, $string);
	
	@array = grep {/[a-z]/} @array;
	
	return @array;
}

# this sub takes two strings and an array ref
# the first string is a phrase
# the second string is the text to search
# the array ref is a list of indices to test

sub Align {
	
	my ($search, $text, $pi_ref) = @_;

	my @search = Clean($search);

	my @phrase_index = @$pi_ref;

	# this holds the max consecutive words matched

	my $max = 0;
	my $decided = $phrase_index[0];

	# try to match words
	# for each of the phrases beginning on this line

	for my $pi (sort @phrase_index) {
	
		my @target = @{$phrase{$text}[$pi]};
	
		my $matched = 0;
	
		# now see how much of the phrase we can match
	
		for my $s (@search) {
			
			if ( grep { $_ eq $s } @target ) { $matched++ }
		}
		
		$matched = sprintf("%.2f", $matched/scalar(@search));
	
		if ($matched > $max)  {
			 
			$max = $matched; 
			$decided = $pi;
		}
	}
	
	unless (defined $decided) {
	
		print STDERR "\$search=$search; \$#phrase_index=$#phrase_index\n";
	}
	
	return ($decided, $max);
}
