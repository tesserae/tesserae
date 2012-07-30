#
# read_table.pl
#
# select two texts for comparison using the big table
#
# The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at ../doc/LICENSE.txt or http://tesserae.caset.buffalo.edu/license.txt.
# 
# Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations under the License.
# 
# The Original Code is this file, read_table.pl.
# 
# The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.
# 
# Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.
# 
# Contributor(s): Neil Coffee, Chris Forstall, James Gawley, J.-P. Koenig, Roelant Ossewaarde, and Shakthi Poornima.
# 
# Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

use strict;
use warnings;

use Getopt::Long;
use Storable qw(nstore retrieve);

use FindBin qw($Bin);

use lib $Bin;

use TessSystemVars;
use EasyProgressBar;

#
# usage
#

my $usage = <<END;

   usage: read_table.pl --source SOURCE --target TARGET [options]

	where options are
	
	   --unit      line|phrase : textual units to match. default is "line".
	   --stopwords N   		   : number of stopwords. default is 10.
		--distance  N           : max distance between matching tokens.  default is 999.
		--output    FILENAME    : output file. otherwise prints to STDOUT
		
	   --quiet     : don't print progress info to STDERR

END

#
# set some parameters
#

# source means the alluded-to, older text

my $source;

# target means the alluding, newer text

my $target;

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = "line";

# feature means the feature set compared: 
# - choice is 'word' or 'stem' or 'syn'

my $feature = "word";

# session is not used in the standalone version

my $session = "standalone";

# stopwords is the number of words on the stoplist

my $stopwords = 10;

# output file

my $file_xml = "none";

# print debugging messages to stderr?

my $quiet = 0;

# maximum span between matching tokens

my $max_dist = 999;

GetOptions( 
	      'source=s'	=> \$source,
			'target=s'	=> \$target,
			'unit=s'	=> \$unit,
			'feature=s'	=> \$feature,
			'stopwords=i' => \$stopwords, 
			'output=s' => \$file_xml,
			'distance=i' => \$max_dist,
			'quiet' 	=> \$quiet );



#
# abbreviations of canonical citation refs
#

my $file_abbr = "$fs_data/common/abbr";
my %abbr = %{ retrieve($file_abbr) };

# $lang sets the language of input texts
# - necessary for finding the files, since
#   the tables are separate.
# - one day, we'll be able to set the language
#   for the source and target independently
# - choices are "grc" and "la"

my $file_lang = "$fs_data/common/lang";
my %lang = %{retrieve($file_lang)};

# if web input doesn't seem to be there, 
# then check command line arguments

unless (defined ($source and $target)) {

	print STDERR $usage;
	exit;
}

unless ($quiet) {

	print STDERR "target=$target\n";
	print STDERR "source=$source\n";
	print STDERR "lang_source=$lang{$source}; lang_target=$lang{$target}\n";
	print STDERR "feature=$feature\n";
	print STDERR "unit=$unit\n";
	print STDERR "stopwords=$stopwords\n";
	print STDERR "max_dist=$max_dist\n";
}


#
# calculate feature frequencies
#

my %freq = %{ retrieve( "$fs_data/v3/$lang{$target}/$target/$target.freq_${feature}")};

#
# create stop list
#

my @stoplist = sort {$freq{$b} <=> $freq{$a}} keys %freq;

if ($stopwords > 0) {
	
	@stoplist = @stoplist[0..$stopwords-1];
}
else {
	
	@stoplist = ();
}

unless ($quiet) { print STDERR "stoplist: " . join(",", @stoplist) . "\n"}

#
# if the featureset is synonyms, get the parameters used
# to create the synonym dictionary for debugging purposes
#

my $max_heads = "NA";
my $min_similarity = "NA";

if ( $feature eq "syn" ) { 

	($max_heads, $min_similarity) = @{ retrieve("$fs_data/common/$lang{$target}.syn.cache.param") };
}


#
# read data from table
#


unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $path_source = "$fs_data/v3/$lang{$source}/$source";

my @token_source   = @{ retrieve( "$path_source/$source.token"    ) };
my @unit_source    = @{ retrieve( "$path_source/$source.${unit}" ) };
my %index_source   = %{ retrieve( "$path_source/$source.index_$feature" ) };

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $path_target = "$fs_data/v3/$lang{$target}/$target";

my @token_target   = @{ retrieve( "$path_target/$target.token"    ) };
my @unit_target    = @{ retrieve( "$path_target/$target.${unit}" ) };
my %index_target   = %{ retrieve( "$path_target/$target.index_$feature" ) };



#
#
# this is where we calculated the matches
#
#

# this hash holds information about matching units

my %match;

#
# consider each key in the source doc
#

unless ($quiet) {

	print STDERR "comparing $target and $source\n";
}

# draw a progress bar

my $pr;

$pr = $quiet ? 0 : ProgressBar->new(scalar(keys %index_source));

# start with each key in the source

for my $key (keys %index_source) {

	# advance the progress bar

	$pr->advance() unless $quiet;

	# skip key if it doesn't exist in the target doc

	next unless ( defined $index_target{$key} );

	# skip key if it's in the stoplist

	next if ( grep { $_ eq $key } @stoplist);

	# 

	for my $token_id_target ( @{$index_target{$key}} ) {

		my $unit_id_target = $token_target[$token_id_target]{uc($unit) . '_ID'};

		for my $token_id_source ( @{$index_source{$key}} ) {

			my $unit_id_source = $token_source[$token_id_source]{uc($unit) . '_ID'};
			
			push @{ $match{$unit_id_target}{$unit_id_source}{TARGET} }, $token_id_target;
			push @{ $match{$unit_id_target}{$unit_id_source}{SOURCE} }, $token_id_source;
			push @{ $match{$unit_id_target}{$unit_id_source}{KEY}    }, $key;
		}
	}
}

#
# remove dups
#

for my $unit_id_target ( keys %match ) {

	for my $unit_id_source ( keys %{$match{$unit_id_target}} ) {
				
		$match{$unit_id_target}{$unit_id_source}{TARGET} = TessSystemVars::uniq($match{$unit_id_target}{$unit_id_source}{TARGET});
		$match{$unit_id_target}{$unit_id_source}{SOURCE} = TessSystemVars::uniq($match{$unit_id_target}{$unit_id_source}{SOURCE});
	}
}


#
#
# assign scores
#
#

# how many matches in all?

my $total_matches = 0;

unless ($quiet) {

	print STDERR "calculating scores\n";
}

# draw a progress bar

$pr = $quiet ? 0 : ProgressBar->new(scalar(keys %match));

#
# look at the matches one by one, according to unit id in the target
#

for my $unit_id_target (sort {$a <=> $b} keys %match)
{

	# advance the progress bar

	$pr->advance() unless $quiet;
	
	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $unit_id_source ( sort {$a <=> $b} keys %{$match{$unit_id_target}})
	{

		# skip any match that doesn't involve two shared features in each text
		
		if ( scalar( @{$match{$unit_id_target}{$unit_id_source}{TARGET}} ) < 2) {
		
			delete $match{$unit_id_target}{$unit_id_source};
			next;
		}
		if ( scalar( @{$match{$unit_id_target}{$unit_id_source}{SOURCE}} ) < 2) {

			delete $match{$unit_id_target}{$unit_id_source};
			next;			
		}

		# this will record which words are to be marked in the display

		my %marked_source;
		my %marked_target;
		
		#
		# here's the place where a scoring algorithm should be
		#
		# - right now we have a placeholder that's a function
		#   of word frequency and distance between words
		
		my $score;
		my $distance = abs($match{$unit_id_target}{$unit_id_source}{TARGET}[-1] - $match{$unit_id_target}{$unit_id_source}{TARGET}[0]);
		
		# examine each shared term in the target in order by position
		# within the line
		
		for my $token_id_target (@{$match{$unit_id_target}{$unit_id_source}{TARGET}} ) {
						
			# mark the display copy as matched

			$marked_target{$token_id_target} = 1;
						
			# add the frequency score for this term
			
			$score += 1;
		}

		#
		# now examine each shared term in the source as above
		#

		$distance += abs($match{$unit_id_target}{$unit_id_source}{SOURCE}[-1] - $match{$unit_id_target}{$unit_id_source}{SOURCE}[0]);
		
		# go through the terms in order by position
		
		for my $token_id_source ( @{$match{$unit_id_target}{$unit_id_source}{SOURCE}} ) {

			# mark the display copy

			$marked_source{$token_id_source} = 1;

			# add the frequency score for this term

			$score += 1;
		}
		
		if ($distance > $max_dist) {
			
			delete $match{$unit_id_target}{$unit_id_source};
			next;
		}
		
		$score = sprintf("%.2f", $score / $distance);
		
		# save calculated score, matched words, etc.
		
		$match{$unit_id_target}{$unit_id_source}{SCORE} = $score;
		$match{$unit_id_target}{$unit_id_source}{MARKED_SOURCE} = {%marked_source};
		$match{$unit_id_target}{$unit_id_source}{MARKED_TARGET} = {%marked_target};
		
		$total_matches++;
	}
}

my %feature_notes = (
	
	word => "Exact matching only.",
	stem => "Stem matching enabled.  Forms whose stem is ambiguous will match all possibilities.",
	syn  => "Stem + synonym matching.  This search is still in development.  Note that stopwords may match on less-common synonyms.  max_heads=$max_heads; min_similarity=$min_similarity"
	
	);


#
# print xml
#

# this line should ensure that the xml output is encoded utf-8

binmode STDOUT, ":utf8";

# format the stoplist

my $commonwords = join(", ", @stoplist);

print STDERR "writing results\n" unless $quiet;

unless ($file_xml eq "none") {

	open FH, ">:utf8", $file_xml || die "can't open $file_xml for writing: $!";
	
	select FH;
}

# draw a progress bar

$pr = $quiet ? 0 : ProgressBar->new(scalar(keys %match));

# print the xml doc header

print <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" unit="$unit" feature="$feature" sessionID="$session" version="3">
	<comments>V3 results. $feature_notes{$feature}</comments>
	<commonwords>$commonwords</commonwords>
END

# now look at the matches one by one, according to unit id in the target

for my $unit_id_target (sort {$a <=> $b} keys %match)
{

	# advance the progress bar

	$pr->advance() unless $quiet;

	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $unit_id_source ( sort {$a <=> $b} keys %{$match{$unit_id_target}})
	{

		# get this parallel's score & marked words from the record

		my $score = $match{$unit_id_target}{$unit_id_source}{SCORE};
		my %marked_source = %{$match{$unit_id_target}{$unit_id_source}{MARKED_SOURCE}};
		my %marked_target = %{$match{$unit_id_target}{$unit_id_source}{MARKED_TARGET}};

		# format the list of all unique shared words
	
		my $keypair = join(", ", @{$match{$unit_id_target}{$unit_id_source}{KEY}});

		# now write the xml record for this match

		print "\t<tessdata keypair=\"$keypair\" score=\"$score\">\n";

		print "\t\t<phrase text=\"source\" work=\"$abbr{$source}\" "
				. "unitID=\"$unit_id_source\" "
				. "line=\"$unit_source[$unit_id_source]{LOCUS}\" "
				. "link=\"NA\">";

		# here we print the unit

		for my $token_id_source (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
		
			if (defined $marked_source{$token_id_source}) { print '<span class="matched">' }

			# print the display copy of the token
		
			print $token_source[$token_id_source]{DISPLAY};
		
			# close the tag if necessary
		
			if (defined $marked_source{$token_id_source}) { print '</span>' }
		}

		print "</phrase>\n";
	
		# same as above, for the target now
	
		print "\t\t<phrase text=\"target\" work=\"$abbr{$target}\" "
				. "unitID=\"$unit_id_target\" "
				. "line=\"$unit_target[$unit_id_target]{LOCUS}\" "
				. "link=\"NA\">";

		for my $token_id_target (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
		
			if (defined $marked_target{$token_id_target}) { print '<span class="matched">' }
			print $token_target[$token_id_target]{DISPLAY};
			if (defined $marked_target{$token_id_target}) { print "</span>" }
		}

		print "</phrase>\n";

		print "\t</tessdata>\n";

	}
}

# finish off the xml doc

print "</results>\n";	

unless ($file_xml eq "none") {

	close FH;
}