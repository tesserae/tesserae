#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Desktop/big_table/perl';	# PERL_PATH

# add_column.pl
#
# add a new text to the big table
# --identical form matching

use strict;
use warnings; 

use TessSystemVars;
use Storable qw(nstore retrieve);

#
# these lines set language-specific variables
# such as what is a letter and what isn't
#

my $lang="grc";

my %non_word = ('la' => qr([^a-zA-Z]+), 'grc' => qr([^a-z\*\(\)\\\/\=\|\+']+));

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV)
{

	# name for the file is everything before .tess
	# not including the path

	my $name = $file_in;
	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words 

	# a list of words

	my @word;

	my @line;
	my @phrase;

	my @loc_line;
	my @loc_phrase;

	my $line_id = 0;
	my $phrase_id = 0;

	my %count;

	my %index_line_int;
	my %index_line_ext;

	my %index_phrase_int;
	my %index_phrase_ext;

	print STDERR "reading text: $file_in\n";

	# open the input text

	open (TEXT, $file_in) or die("Can't open file ".$file_in);

	# examine each line of the input text

	while (my $l = <TEXT>)
	{
		# leave the newline for now

		# parse a line of text; reads in verse number and the verse. Assumption is that a line looks like:
		# <001> this is a verse

		$l =~ /^<(.+)>\s+(.+)/;

		my ($verseno, $verse) = ($1, $2);

	    # skip lines with no locus or line

	    next unless (defined $verseno and defined $verse);

		# record the locus of each line

		$verseno =~ s/^.*\s//;

		$loc_line[$line_id] = $verseno;

		# assign to each phrase the locus of the line where it begins

		if ( !defined $loc_phrase[$phrase_id] )
		{
			$loc_phrase[$phrase_id] = $verseno;
		}

		# if a line begins with spaces or phrase-punct chars, delete them

		$verse =~ s/^[\.\?\!;:\s]+//;

		# divide the line on phrase punct

		my @chunk = split /[\.\?\!;:]/, $verse;

		for (0..$#chunk)
		{
			# if there are multiple phrases on this line, add each one in turn

			if ($_ > 0)
			{
				$phrase_id++;

				$loc_phrase[$phrase_id] = $verseno;
			}

			# remove html special chars

			$verse =~ s/&[a-z];//ig;

			# split into words

			my @words = split ($non_word{$lang}, $chunk[$_]);

			# add words to the current phrase, line

			for (@words)
			{
				chomp;

				next if ($_ eq "");

				# convert to lower-case
				# the wisdom of this could be disputed, but roelant does it too

				my $key = lc($_);

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

				push @{$phrase[$phrase_id]}, $key;
				push @{$index_phrase_int{$key}}, $#{$phrase[$phrase_id]};
				push @{$index_phrase_ext{$key}}, $phrase_id;

				push @{$line[$line_id]}, $key;
				push @{$index_line_int{$key}}, $#{$line[$line_id]};		
				push @{$index_line_ext{$key}}, $line_id;
			}
		}

		# increment line_id

		$line_id++;
	}

	close TEXT;

	print scalar(@line) . " lines\n";
	print scalar(@phrase) . " phrases\n";

	#
	# save the data using Storable
	# 

	my $file_out = "data/$lang/word/$name";

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
}
