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

use File::Path qw(make_path remove_tree);
use Storable qw(nstore retrieve);

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

my $lang;
my $lang_override;

my $wchar_greek = 'a-z\*\(\)\\\/\=\|\+\'';
my $wchar_latin = 'a-zA-Z';

my %non_word = (
	'la' => qr([^$wchar_latin]+), 
	'grc' => qr([^$wchar_greek]+) );
my %is_word = (
	'la' => qr([$wchar_latin]+), 
	'grc' => qr([$wchar_greek]+) );
		   

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV)
{

	# allow language to be set from cmd line args

	if ($file_in =~ /^--(la|grc)/)
	{
		$lang_override = $1;
		next;
	}

	#
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if ($file_in !~ /\.tess/)
	{
		if (-d $file_in)
		{
			opendir (DH, $file_in);

			push @ARGV, (grep {/\.part\./ && -f} map { "$file_in/$_" } readdir DH);

			closedir (DH);
		}

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

	if ( defined $lang_override )
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
		die "please specify language using --la|grc";
	}

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words
	
	# an array of features
	
	my @word;

	# an array of units

	my @line;
	my @phrase;

	# locus of the first line of each unit

	my @loc_line;
	my @loc_phrase;
	
	# unit id

	my $line_id = 0;
	my $phrase_id = 0;

	# counts unique word forms

	my %count;
	
	# an index of all the units containing a given word

	my %index_line_int;
	my %index_line_ext;

	my %index_phrase_int;
	my %index_phrase_ext;
	
	# this holds the abbreviation for the author/work

	my %ref;
	
	# a display copy of each line
	
	my @space;
	
	# a list of every line a phrase includes
	
	my @phrase_lines;

	print STDERR "reading text: $file_in\n";

	# open the input text

	open (TEXT, $file_in) or die("Can't open file ".$file_in);

	# examine each line of the input text

	while (my $l = <TEXT>)
	{
		# leave the newline for now

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001>	this is a verse

		$l =~ /^<(.+)>\s+(.+)/;

		my ($verseno, $verse) = ($1, $2);

		# skip lines with no locus or line

		next unless (defined $verseno and defined $verse);

		# examine the locus of each line

		$verseno =~ s/^(.*)\s//;
		
		# save the abbreviation of the author/work
		
		$ref{$1}++;

		# save the book/poem/line number

		$loc_line[$line_id] = $verseno;

		# add the current line to the list for the current phrase

		push @{$phrase_lines[$phrase_id]}, $line_id;

		# remove html special chars

		$verse =~ s/&[a-z];//ig;
				
		# save the inter-word material
				
		my @spaces = split ($is_word{$lang}, $verse);

		# split into words

		my @words = split ($non_word{$lang}, $verse);
			
		# make sure the arrays align correctly
		# spaces should have one extra element
			
		if ($words[0] eq "")		{ shift @words }
		
		# add words to the current phrase, line

		for my $i (0..$#words)
		{
				
			# convert to lower-case
			# the wisdom of this could be disputed, but roelant does it too

			my $key = lc($words[$i]);

			$count{$key}++;
				
			# add the word to a bunch of indices
			#
			# there's some more detail about these in read_table.pl
			# and I'll write proper documentation later.
			#
			# @phrase is an array of phrases
			#   - the index is serial phrase id
			#	- each value is an anonymous array of the words in that phrase
			#
			# %index_phrase_ext is a hash of phrase ids in which the word occurs
			#   - the keys are words 
			#	- the values are anonymous arrays of phrase ids
			#
			# %index_phrase_int is a hash of phrase-internal word positions
			#    corresponding to the phrases in %index_phrase_ext
			#   - the keys are words
			#   - the values are word position in a phrase
				
			push @word, $words[$i];

			push @{$line[$line_id]{SPACE}}, $spaces[$i];
			push @{$line[$line_id]{WORD}}, $#word;
			push @{$index_line_int{$key}}, $#{$line[$line_id]{WORD}};		
			push @{$index_line_ext{$key}}, $line_id;

			if ($i == 0 and $#{$phrase[$phrase_id]{SPACE}} > -1)
			{
				$spaces[$i] = " / " . $spaces[$i];
			}
			
			
			if ($i == 0 and $#{$phrase[$phrase_id]{SPACE}} > $#{$phrase[$phrase_id]{WORD}})
			{
				${$phrase[$phrase_id]{SPACE}}[$#{$phrase[$phrase_id]{SPACE}}] .= $spaces[$i];
			}
			else
			{
				push @{$phrase[$phrase_id]{SPACE}}, $spaces[$i];
			}
			
			if ($spaces[$i] =~ /[\.\?\!\;\:]/) 
			{
				$phrase_id++;
				
				push @{$phrase[$phrase_id]{SPACE}}, "";
				
				push @{$phrase_lines[$phrase_id]}, $line_id;
			}
			
			push @{$phrase[$phrase_id]{WORD}}, $#word;
			push @{$index_phrase_int{$key}}, $#{$phrase[$phrase_id]{WORD}};
			push @{$index_phrase_ext{$key}}, $phrase_id;
		}

		if ($#spaces > $#words)
		{
			push @{$phrase[$phrase_id]{SPACE}}, $spaces[$#spaces];
			
			if ($spaces[$#spaces] =~ /[\.\?\!\;\:]/) 
			{ 
				$phrase_id++;
			}
			
			push @{$line[$line_id]{SPACE}}, $spaces[$#spaces];
		}
		else
		{
			push @{$line[$line_id]{SPACE}}, "";
		}
		
		# increment line_id

		$line_id++;
	}

	close TEXT;

	print scalar(@line) . " lines\n";
	print scalar(@phrase) . " phrases\n";

	
	for my $i (0..$#phrase)
	{
		$loc_phrase[$i] = $loc_line[$phrase_lines[$i][0]];
	
		if ($#{$phrase[$i]{SPACE}} == $#{$phrase[$i]{WORD}})
		{
			push @{$phrase[$i]{SPACE}}, "";
		}
	}
	
	#
	# save the data using Storable
	# 

	# make sure the directory exists
	
	unless (-d "$fs_data/v3/$lang/word" ) { make_path ("$fs_data/v3/$lang/word") }

	my $file_out = "$fs_data/v3/$lang/word/$name";

	print "writing $file_out.word\n";
	nstore \@word, "$file_out.word";

	print "writing $file_out.space\n";
	nstore \@space, "$file_out.space";
	
	print "writing $file_out.line\n";
	nstore \@line, "$file_out.line";

	print "writing $file_out.phrase\n";
	nstore \@phrase, "$file_out.phrase";

	print "writing $file_out.count\n";
	nstore \%count, "$file_out.count";

	print "writing $file_out.index_phrase_int\n";
	nstore \%index_phrase_int, "$file_out.index_phrase_int";

	print "writing $file_out.index_phrase_ext\n";
	nstore \%index_phrase_ext, "$file_out.index_phrase_ext";

	print "writing $file_out.index_line_int\n";
	nstore \%index_line_int, "$file_out.index_line_int";

	print "writing $file_out.index_line_ext\n";
	nstore \%index_line_ext, "$file_out.index_line_ext";

	print "writing $file_out.loc_line\n";
	nstore \@loc_line, "$file_out.loc_line";

	print "writing $file_out.loc_phrase\n";
	nstore \@loc_phrase, "$file_out.loc_phrase";

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
