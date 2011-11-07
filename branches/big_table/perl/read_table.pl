#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Desktop/big_table/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

use strict;
use warnings;

use Storable;
use TessSystemVars;

#
# set some parameters
#  - from command line arguments if any
#  - otherwise use default vergil-lucan case

# source means the alluded-to, 	older text
# target means the alluding, 	newer text

my $source = 'vergil.aeneid';
my $target = 'lucan.bc.1';

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = 'phrase';

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = 'stem';

# check command line arguments
{
	my @text;

	for (@ARGV)
	{
		if 		( /--word/ )	{ $feature='word' }
		elsif 	( /--line/ )	{ $unit='line' }
		else
		{
			push @text, $_;
		}
	}

	if (@text)
	{
		$target = shift @text || die "no target specified";
		$source = shift @text || die "no source specified";
	}
}

# a stop list
# - hard coded in TessSystemVars, work on this in future
# - feature-set-specific

my @stoplist = @{ $TessSystemVars::new_stoplist{$feature} };

#
# read data from table
#

# about these data structures
# 
#    @unit_source
#
#    this is an array of all the phrases/lines in the source text
#	 each element is an anonymous array of words
#
#    you can address any individual word in two dimensions:
# 	    $unit_source[$source_ref_ext][$source_ref_int]
#    where
#		$source_ref_ext = line number (serial, starting at 0)
#		$source_ref_int	= word's position in the line (ditto)
#
#	@loc_source
#
#	this contains the canonical locus citation for each unit
#
# 	%index_source_ext and %index_source_int
#
#	these hashes work together to provide an index of all the
#	features in the text.  one gives line numbers and the other
#	gives the position in its line of each feature, both are
#	indexed by the features themselves.
#
#	so, in the case where $unit='line' and $feature='word':
#
#		$index_source_ext{'arma'} 
#			gives an array of line numbers where arma occurs
#
#		$index_source_int{'arma'}
#			gives an array of line-internal word positions
#
#		the two arrays will have the same number of elements
#		and their elements are co-ordinated.		
#
#	let's say we want to find the first occurrence of 'arma'
#	
#		$source_ref_ext = ${$index_source_ext{'arma'}}[0];
#		$source_ref_int = ${$index_source_int{'arma'}}[0];
#	then
#		$unit_source[$source_ref_ext][$source_ref_int] eq 'arma'
#
#	switch 'source' and 'target' and you get the same info for
#   the other text.

print STDERR "reading source data\n";

my @unit_source = @{ retrieve( "data/word/$source.${unit}" ) };
my @loc_source =  @{ retrieve( "data/word/$source.loc_${unit}" ) };

my %index_source_ext = %{ retrieve( "data/$feature/$source.index_${unit}_ext" ) };
my %index_source_int = %{ retrieve( "data/$feature/$source.index_${unit}_int" ) };

print STDERR "reading target data\n";

my @unit_target = @{ retrieve( "data/word/$target.${unit}" ) };
my @loc_target  = @{ retrieve( "data/word/$target.loc_${unit}" ) };

my %index_target_ext = %{ retrieve( "data/$feature/$target.index_${unit}_ext" ) };
my %index_target_int = %{ retrieve( "data/$feature/$target.index_${unit}_int" ) };

#
# some more crazy data structures
#
# these are designed to hold information about matches
# 	- that is, roelant's "parallels"
#
# here's how they work:
#
# @match_target is an array
# 	- the index is serial unit id in the target, i.e. $target_ref_ext.
#   - the elements are anonymous hashes
#		- the keys to each hash are unit ids in the source text, 
#				i.e. $source_ref_ext
#		- the values to each hash are anonymous arrays
#				of unit-internal word positions in the *target*
#		- whence the "target" in the name of the array above
#
# @match_source is almost the same
#	- the index is still unit id in the *target*
#	- the keys to the anonymous hashes are still unit id in the *source*
#	- but the unit-internal word positions stored in the lowest
#		level anonymous arrays are now for the *source* text
#	- whence the "source" in the name of the high-level array
#
#	let's stop here for a second.
#
#	in addressing a match, in either @match_source or @match_target, 
#	unit ids always go in the same order:
#		$target_ref_ext is the index of the high-level array
#		$source_ref_ext is the key to the anonymous hash
#
#	if you want to find the internal address of a word in the source, 
#	look to @match_source, of a word in the target, @match_target.
#
# examples:
# 	if we want to find out which units in the target match something in the source
#		grep { defined $match_target[$_] } (0..$#match_target)
#
#	if we want to find out which units in the source match a given unit in target
#		keys %{ $match_target[$target_ref_ext] }

my @match_target;
my @match_source;

# consider each key in the source doc

print STDERR "comparing $target and $source\n";

# draw a progress bar

print STDERR "0% |" . (" "x40) . "| 100%\r0% |";

my $progress = 0;
my $last_progress = 0;
my $end_point = scalar(keys %index_source_ext);

# start with each key in the source

for my $key (sort keys %index_source_ext)
{
	# advance the progress bar

	$progress++;

	if ($progress/$end_point > $last_progress+.025)
	{
		print STDERR ".";
		$last_progress = $progress/$end_point;
	}

	# skip key if it doesn't exist in the target doc

	next unless ( defined $index_target_ext{$key} );

	# skip key if it's in the stoplist

	next if ( grep { $_ eq $key } @stoplist);

	# for each unit id in the target having that feature,

	for my $i ( 0..$#{$index_target_ext{$key}} )
	{
		my $target_ref_int = ${$index_target_int{$key}}[$i];
		my $target_ref_ext = ${$index_target_ext{$key}}[$i];

		for my $j ( 0..$#{$index_source_ext{$key}} )
		{
			my $source_ref_int = ${$index_source_int{$key}}[$j];
			my $source_ref_ext = ${$index_source_ext{$key}}[$j];

			${$match_target[$target_ref_ext]}{$source_ref_ext}{$target_ref_int} += 1;
			${$match_source[$target_ref_ext]}{$source_ref_ext}{$source_ref_int} += 1;
		}
	}
}

print STDERR "\n";

print STDERR "writing xml output\n";

# this line should ensure that the xml output is encoded utf-8

binmode STDOUT, ":utf8";

# format the stoplist

my $commonwords = join(", ", @stoplist);

# print the xml doc header

print <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" sessionID="NA">
	<comments>Test results from Big Table</comments>
	<commonwords>$commonwords</commonwords>
END

# now look at the matches one by one, according to unit id in the target

for my $target_ref_ext (0..$#match_target)
{

	# skip anything that doesn't have a match in the source

	next unless defined ($match_target[$target_ref_ext]);

	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $source_ref_ext ( sort {$a <=> $b} keys %{$match_target[$target_ref_ext]})
	{

		# skip any match that doesn't involve two shared features in each text
		
		next if ( scalar( keys %{$match_target[$target_ref_ext]{$source_ref_ext}} ) < 2);
		next if ( scalar( keys %{$match_source[$target_ref_ext]{$source_ref_ext}} ) < 2);

		# these arrays will be used to reconstitute the original line/phrase from the
		# array of words.  having a copy specifically for display is useful because we
		# want to be able to mark certain words as matched with html tags.

		my @display_source = @{$unit_source[$source_ref_ext]};
		my @display_target = @{$unit_target[$target_ref_ext]};

		# this array will hold shared words in the target

		my @target_terms;

		# examine each shared term in the target
		#  - add it to the list
		#  - mark the display copy as matched

		for my $target_ref_int ( keys %{$match_target[$target_ref_ext]{$source_ref_ext}} )
		{
			push @target_terms, $unit_target[$target_ref_ext][$target_ref_int];
			$display_target[$target_ref_int] = "<span class=\"matched\">$unit_target[$target_ref_ext][$target_ref_int]</span>";
		}

		# this array will hold shared words in the source

		my @source_terms;

		# examine each shared term in the source
		# - as above
		
		for my $source_ref_int ( keys %{$match_source[$target_ref_ext]{$source_ref_ext}} )
		{
			push @source_terms, $unit_source[$source_ref_ext][$source_ref_int];
			$display_source[$source_ref_int] = "<span class=\"matched\">$unit_source[$source_ref_ext][$source_ref_int]</span>";
		}

		# this is just a list of all unique shared words

		my $keypair = join(", ", @{TessSystemVars::uniq([@source_terms, @target_terms])});

		# now write the xml record for this match

		print "\t<tessdata keypair=\"$keypair\" score=\"NA\">\n";

		print "\t\t<phrase text=\"source\" work=\"$abbr{$source}\" line=\"$loc_source[$source_ref_ext]\" link=\"NA\">"
				. join(" ", @display_source)
				. "</phrase>\n";
		print "\t\t<phrase text=\"target\" work=\"$abbr{$target}\" line=\"$loc_target[$target_ref_ext]\" link=\"NA\">"
				. join(" ", @display_target)
				."</phrase>\n";

		print "\t</tessdata>\n";
	}
}

# finish off the xml doc

print "</results>\n";
