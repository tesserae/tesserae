#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

# add_column.pl
#
# add a new text to the big table
# --identical form matching

use strict;
use warnings; 

use TessSystemVars;

use File::Path qw(mkpath rmtree);
use Storable qw(nstore retrieve);
use Getopt::Long;

#
# these lines set language-specific variables
# such as what is a letter and what isn't
#

my %abbr;
my $file_abbr = "$fs_data/common/abbr";
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

my %lang;
my $file_lang = "$fs_data/common/lang";

if (-s $file_lang )	{ %lang = %{retrieve($file_lang)} }

#
# allow language for individual files to be given on the
# command line, using flags --la or --grc
#

my %lang_override;
my @force_la;
my @force_grc;

GetOptions("la=s" => \@force_la, "grc=s" => \@force_grc);

for (@force_la)  { $lang_override{$_} = "la" }
for (@force_grc) { $lang_override{$_} = "grc" }

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV)
{

	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if ($file_in !~ /\.tess/)
	{
		# if it is, add all the .tess files in it
		
		if (-d $file_in)
		{
			opendir (DH, $file_in);

			my @parts = (grep {/\.part\./ && -f} map { "$file_in/$_" } readdir DH);

			push @ARGV, @parts;
			
			# if lang_override was set for the directory,
			# apply to all the contents
			
			if (defined $lang_override{$file_in}) { 
				
				for (@parts) { $lang_override{$_} = $lang_override{$file_in}}
			}

			closedir (DH);
		}
		
		# move on to the next full text

		next;
	}

	# the header for the column will be the filename 
	# minus the path and .tess extension

	my $name = $file_in;

	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	# get the language for this doc.  try:
	# 1. user specified at cmd line
	# 2. cached from a previous successful parse
	# 3. somewhere in the path to the text
	# - then give up

	if ( defined $lang_override{$file_in} )
	{
		$lang = $lang_override;
	}
	elsif ( defined $lang{$name} )			
	{ 
		$lang = $lang{$name};
	}
	elsif ($file_in =~ /\/(la|grc)\//)
	{
		$lang = $1;
	}
	else
	{
		print STDERR "Can't guess the language of $file_in!  Skipping.\nTry again, specifying language using --la|grc.\n";
		next;
	}

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words
	
	# an array of features
	
	my @word;
	
	# this parallels @word, but keeps the words as
	# they appear in the original text.
	
	my @display;

	# an array of units

	my @line;
	my @phrase;
	
	# unit id

	my $line_id = 0;
	my $phrase_id = 0;

	# counts unique word forms

	my %count;
	
	# an index of all the units containing a given word

	my %index_word;
	my @index_line;
	my @index_phrase;
	
	# this holds the abbreviation for the author/work

	my %ref;
		
	# a list of every line a phrase includes
	
	my @phrase_lines;

	print STDERR "reading text: $file_in\n";

	# open the input text

	open (TEXT, "<:utf8", $file_in) or die("Can't open file ".$file_in);

	# examine each line of the input text

	while (my $l = <TEXT>)
	{
		# leave the newline for now

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001>	this is a verse

		$l =~ /^<(.+)>\s+(.+)/;

		my ($locus, $verse) = ($1, $2);

		# skip lines with no locus or line

		next unless (defined $locus and defined $verse);

		# examine the locus of each line

		$locus =~ s/^(.*)\s//;
		
		# save the abbreviation of the author/work
		
		$ref{$1}++;

		# save the book/poem/line number

		$line[$line_id]{LOCUS} = $locus;

		# add the current line to the list for the current phrase

		push @{$phrase_lines[$phrase_id]}, $line_id;

		# remove html special chars

		$verse =~ s/&[a-z];//ig;
				
		# save the inter-word material
				
		my @punct = split ($is_word{$lang}, $verse);

		# split into words

		my @words = split ($non_word{$lang}, $verse);
			
		# make sure the arrays align correctly
		# spaces should have one extra element
			
		if ($words[0] eq "")		{ shift @words }
		
		# add words to the current phrase, line

		for my $i (0..$#words)
		{
			
			# first thing, save the word as printed in @display.
			
			push @display, $words[$i];
			
			if ($lang eq "grc") {
				
				$display[-1] = TessSystemVars::beta_to_uni($display[-1]);
			}
			
			# flatten orthographic variation
			# the wisdom of this could be disputed, but roelant does it too

			my $key = TessSystemVars::lcase($lang, $words[$i]);
			$key = TessSystemVars::standardize($lang, $key);

			$count{$key}++;
				
			# add the word to the master list for this text
			
			push @word, $words[$i];
			
			# add the current word, space to the current line

			push @{$line[$line_id]{PUNCT}}, $punct[$i];
			push @{$line[$line_id]{WORD}}, $#word;
			
			# add to the index of all words
			
			push @{$index_word{$key}}, $#word;
			
			# add to the line-lookup
			
			$index_line[$#word] = $line_id;

			# this adds a line-break char to the phrase if
			# we're at the start of a line but the middle of a phrase
			
			if ($i == 0 and $#{$phrase[$phrase_id]{PUNCT}} > -1)
			{
				$punct[$i] = " / " . $punct[$i];
			}
			
			# this merges trailing punct from a previous line with
			# leading punct in the current one if we're at line
			# beginning and mid-phrase
			
			if ($i == 0 and $#{$phrase[$phrase_id]{PUNCT}} > $#{$phrase[$phrase_id]{WORD}})
			{
				${$phrase[$phrase_id]{PUNCT}}[-1] .= $punct[$i];
			}
			else
			{
				push @{$phrase[$phrase_id]{PUNCT}}, $punct[$i];
			}
			
			# this increments the phrase counter if the current inter-
			# word material includes a phrase boundary marker.
			
			if ($punct[$i] =~ /[\.\?\!\;\:]/) 
			{
				$phrase_id++;
				
				push @{$phrase[$phrase_id]{PUNCT}}, "";
				
				push @{$phrase_lines[$phrase_id]}, $line_id;
			}
			
			# add the current word to the current phrase
			
			push @{$phrase[$phrase_id]{WORD}}, $#word;
			
			# add this word to the phrase-lookup
			
			$index_phrase[$#word] = $phrase_id;
		}
		
		# add trailing spaces to the current phrase.
		# If they include a phrase boundary marker,
		# then the next line is a new phrase.

		if ($#punct > $#words)
		{
			push @{$phrase[$phrase_id]{PUNCT}}, $punct[-1];
			
			if ($punct[-1] =~ /[\.\?\!\;\:]/) 
			{ 
				$phrase_id++;
			}
			
			push @{$line[$line_id]{PUNCT}}, $punct[-1];
		}
		else
		{
			push @{$line[$line_id]{PUNCT}}, "";
		}
		
		# increment line_id

		$line_id++;
	}

	close TEXT;

	print scalar(@line) . " lines\n";
	print scalar(@phrase) . " phrases\n";

	# once we know how many lines are in each
	# phrase, go back and set the phrase locus
	# to that of the first line it includes.
	
	for my $i (0..$#phrase)
	{
		$phrase[$i]{LOCUS} = $line[$phrase_lines[$i][0]]{LOCUS};
	
		if ($#{$phrase[$i]{PUNCT}} == $#{$phrase[$i]{WORD}})
		{
			push @{$phrase[$i]{PUNCT}}, "";
		}
	}
	
	#
	# save the data using Storable
	# 

	# make sure the directory exists
	
	my $path_data = "$fs_data/test/$lang/$name";
	
	unless (-d $path_data ) { mkpath($path_data) }

	my $file_out = "$path_data/$name";

	print "writing $file_out.word\n";
	nstore \@word, "$file_out.word";

	print "writing $file_out.display\n";
	nstore \@display, "$file_out.display";
	
	print "writing $file_out.line\n";
	nstore \@line, "$file_out.line";

	print "writing $file_out.phrase\n";
	nstore \@phrase, "$file_out.phrase";

	print "writing $file_out.count\n";
	nstore \%count, "$file_out.count";

	print "writing $file_out.index_word\n";
	nstore \%index_word, "$file_out.index_word";

	print "writing $file_out.index_line\n";
	nstore \@index_line, "$file_out.index_line";
	
	print "writing $file_out.index_phrase\n";
	nstore \@index_phrase, "$file_out.index_phrase";

	print "writing $file_out.phrase_lines\n";
	nstore \@phrase_lines, "$file_out.phrase_lines";

	# add this ref to the database of abbreviations

	unless (defined $abbr{$name})
	{	
		$abbr{$name} = (sort { $ref{$b} <=> $ref{$a} } keys %ref)[0];
		nstore \%abbr, $file_abbr;
	}

	# save the language designation for this file

	unless (defined $lang{$name})
	{
		$lang{$name} = $lang;
		nstore \%lang, $file_lang;
	}
}
