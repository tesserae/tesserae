#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

use strict;
use warnings;

use Storable qw(nstore retrieve);

use TessSystemVars;

#
# is the program being run from the command line or
# the web interface?

my $output = "html";
my $quiet = 1;

if ((getpwuid($>))[0] ne $apache_user) 
{
	$output = "cmdline";
}

# html header
#
# put this stuff early on so the web browser doesn't
# give up

if ($output eq "html")
{
	use CGI qw/:standard/;

	print header;

	my $stylesheet = "$url_css/style.css";

	print <<END;

<html>
<head>
	<title>Tesserae results</title>
   <link rel="stylesheet" type="text/css" href="$stylesheet" />

END

}

#
# set some parameters
#  - from command line arguments if any
#  - otherwise use default vergil-lucan case

#
# determine the session ID
# 

# open the temp directory
# and get the list of existing session files

opendir(my $dh, $fs_tmp) || die "can't opendir $fs_tmp: $!";

my @tes_sessions = grep { /^tesresults-[0-9a-f]{8}\.xml/ && -f "$fs_tmp/$_" } readdir($dh);

closedir $dh;

# sort them and get the id of the last one

@tes_sessions = sort(@tes_sessions);

my $session = $tes_sessions[-1];

# then add one to it;
# if we can't determine the last session id,
# then start at 0

if (defined($session))
{
   $session =~ s/^.+results-//;
   $session =~ s/\.xml//;
}
else
{
   $session = "0"
}

# put the id into hex notation to save space and make it look confusing

$session = sprintf("%08x", hex($session)+1);

# open the new session file for output

my $session_file = "$fs_tmp/tesresults-$session.xml";

if ($output eq "html")
{
	open (XML, '>' . $session_file) || die "can't open " . $session_file . ':' . $!;
}
else
{
	open (XML, ">&STDOUT") || die "can't write to STDOUT";
}
#
# set some parameters using web-form input
#

# source means the alluded-to, older text

my $source;

# target means the alluding, newer text

my $target;

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit;

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature;

# stopwords is the number of words on the stoplist

my $stopwords;

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

if ( $output eq "html") {

	my $query = new CGI || die "$!";

	$source		= $query->param('source') || "";
	$target		= $query->param('target') || "";
	$unit     	= $query->param('unit')   || "line";
	$feature		= $query->param('feature')		|| "stem";
	$stopwords	= $query->param('stoplist')	|| 10;

	if ($source eq "" or $target eq "") {
	
		die "read_table.pl called from web interface with no source/target";
	}
}
else {

	$quiet = 0;

	my @text;

	$feature = "word";
	$unit		= "line";
	$stopwords = 10;

	for (@ARGV) {

		if 	( /--word/ )			{ $feature = 'word' }
		elsif ( /--stem/ )			{ $feature = 'stem' }
		elsif ( /--line/ )			{ $unit = 'line' }
		elsif ( /--phrase/ )			{ $unit = 'phrase' }
		elsif	( /--session=(\w+)/)	{ $session = $1 }
		else {
		
			unless (/^--/) {

				push @text, $_;
			}
		}
	}

	if (@text) {

		$target = shift @text || die "no target specified";
		$source = shift @text || die "no source specified";
	}
}

# a stop list
# - hard coded in TessSystemVars, work on this in future
# - feature-set-specific

print STDERR "debug: target=$target; source=$source; lang=$lang{$target}; feature=$feature\n";

my @stoplist = @{$top{$lang{$target} . '_' . $feature}};

if ($stopwords > 0) {

	@stoplist = @stoplist[0..$stopwords-1];
}
else {

	@stoplist = ();
}

my %freq = %{ retrieve( "$fs_data/common/$lang{$target}.${feature}_count" )};

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

if ($output ne "html")
{
	print STDERR "reading source data\n";
}

my $path_base = $fs_data . "/test";

my @word_source    = @{ retrieve( "$path_base/$lang{$source}/word/$source.word"    ) };
my @display_source = @{ retrieve( "$path_base/$lang{$source}/word/$source.display" ) };
my @unit_source    = @{ retrieve( "$path_base/$lang{$source}/word/$source.${unit}" ) };

my %index_feature_source = %{ retrieve( "$path_base/$lang{$source}/$feature/$source.index_$feature" ) };
my @index_unit_source = @{ retrieve( "$path_base/$lang{$source}/word/$source.index_$unit" ) };

my @phrase_lines_source = @{ retrieve( "$path_base/$lang{$source}/word/$source.phrase_lines" )};

if ($output ne "html")
{
	print STDERR "reading target data\n";
}

my @word_target    = @{ retrieve( "$path_base/$lang{$target}/word/$target.word"    ) };
my @display_target = @{ retrieve( "$path_base/$lang{$target}/word/$target.display" ) };
my @unit_target    = @{ retrieve( "$path_base/$lang{$target}/word/$target.${unit}" ) };

my %index_feature_target = %{ retrieve( "$path_base/$lang{$target}/$feature/$target.index_$feature" ) };
my @index_unit_target = @{ retrieve( "$path_base/$lang{$target}/word/$target.index_$unit" ) };

my @phrase_lines_target = @{ retrieve( "$path_base/$lang{$target}/word/$target.phrase_lines" )};


# this will record which words are to be marked in the display

my %marked_source;
my %marked_target;

#
# this is where we calculated the matches
#

# this holds information about matches
# 	- that is, roelant's "parallels"
#

my %match;

#
# consider each key in the source doc
#

if ($output ne "html")
{
	print STDERR "comparing $target and $source\n";
}

# draw a progress bar

if ($quiet == 0)
{
	print STDERR "0% |" . (" "x40) . "| 100%\r0% |";
}

my $progress = 0;
my $last_progress = 0;
my $end_point = scalar(keys %index_feature_source);

# start with each key in the source

for my $key (sort keys %index_feature_source)
{
	# advance the progress bar

	$progress++;

	if ($quiet == 0)
	{
		if ($progress/$end_point > $last_progress+.025)
		{
			if ($output ne "html")
			{
				print STDERR ".";
			}
			$last_progress = $progress/$end_point;
		}
	}

	# skip key if it doesn't exist in the target doc

	next unless ( defined $index_feature_target{$key} );

	# skip key if it's in the stoplist

	next if ( grep { $_ eq $key } @stoplist);

	# for each unit id in the target having that feature,

	for my $i ( 0..$#{$index_feature_target{$key}} )
	{
		my $target_word_id = ${$index_feature_target{$key}}[$i];
		my $target_unit_id = $index_unit_target[$target_word_id];

		for my $j ( 0..$#{$index_feature_source{$key}} )
		{
			my $source_word_id = ${$index_feature_source{$key}}[$j];
			my $source_unit_id = $index_unit_source[$source_word_id];
			
			push @{ $match{$target_unit_id}{$source_unit_id}{TARGET} }, $target_word_id;
			push @{ $match{$target_unit_id}{$source_unit_id}{SOURCE} }, $source_word_id;
		}
	}
}

#
# remove dups
#

for my $target_unit_id ( keys %match ) {

	for my $source_unit_id ( keys %{$match{$target_unit_id}} ) {
				
		$match{$target_unit_id}{$source_unit_id}{TARGET} = TessSystemVars::uniq($match{$target_unit_id}{$source_unit_id}{TARGET});
		$match{$target_unit_id}{$source_unit_id}{SOURCE} = TessSystemVars::uniq($match{$target_unit_id}{$source_unit_id}{SOURCE});
	}
}



#
# assign scores, write output
#

if ($output ne "html")
{
	print STDERR "\n";

	print STDERR "writing xml output\n";
}

# draw a progress bar

if ($quiet == 0)
{
	print STDERR "0% |" . (" "x40) . "| 100%\r0% |";
}

$progress = 0;
$last_progress = 0;
$end_point = scalar(keys %match);

# this line should ensure that the xml output is encoded utf-8

binmode XML, ":utf8";

# format the stoplist

my $commonwords = join(", ", @stoplist);

# print the xml doc header

print XML <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" sessionID="$session">
	<comments>V3 results from read_table2.pl</comments>
	<commonwords>$commonwords</commonwords>
END

# now look at the matches one by one, according to unit id in the target

for my $target_unit_id (sort {$a <=> $b} keys %match)
{

	# advance the progress bar

	$progress++;

	if ($quiet == 0) {
		
		if ($progress/$end_point > $last_progress+.025) {
			
			if ($output ne "html") {
				
				print STDERR ".";
			}
			$last_progress = $progress/$end_point;
		}
	}

	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $source_unit_id ( sort {$a <=> $b} keys %{$match{$target_unit_id}})
	{

		# skip any match that doesn't involve two shared features in each text
		
		next if ( scalar( @{$match{$target_unit_id}{$source_unit_id}{TARGET}} ) < 2);
		next if ( scalar( @{$match{$target_unit_id}{$source_unit_id}{SOURCE}} ) < 2);

		# this array will hold shared words in the target

		my @target_terms;
		
		#
		# here's the place where a scoring algorithm should be
		#
		# - right now we have a placeholder that's a function
		#   of word frequency and distance between words
		
		my $score;
		my $distance = ${$match{$target_unit_id}{$source_unit_id}{TARGET}}[-1] - ${$match{$target_unit_id}{$source_unit_id}{TARGET}}[0];
		
		# examine each shared term in the target in order by position
		# within the line
		
		for my $target_word_id (@{$match{$target_unit_id}{$source_unit_id}{TARGET}} )
		{
			
			# add this term to the list of shared terms
			
			push @target_terms, $display_target[$target_word_id];
			
			# mark the display copy as matched

			$marked_target{$target_word_id} = 1;
						
			# add the frequency score for this term
			
			$score += 1;
		}

		# this array will hold shared words in the source

		my @source_terms;

		#
		# now examine each shared term in the source as above
		#

		$distance += ${$match{$target_unit_id}{$source_unit_id}{SOURCE}}[-1] - ${$match{$target_unit_id}{$source_unit_id}{SOURCE}}[0];
		
		# go through the terms in order by position
		
		for my $source_word_id ( @{$match{$target_unit_id}{$source_unit_id}{SOURCE}} )
		{
			# add the term to shared terms
			
			push @source_terms, $display_source[$source_word_id];
			
			# mark the display copy

			$marked_source{$source_word_id} = 1;

			# add the frequency score for this term

			$score += 1;
		}
		
		# format the list of all unique shared words

		my @combined_terms = (@source_terms, @target_terms);

		my $keypair = join(", ", @combined_terms);

		# now write the xml record for this match

		print XML "\t<tessdata keypair=\"$keypair\" score=\"" . sprintf("%.2f", $score/($distance || 1)) . "\">\n";

		print XML "\t\t<phrase text=\"source\" work=\"$abbr{$source}\" "
				. "line=\"$unit_source[$source_unit_id]{LOCUS}\" "
				. "link=\"$url_cgi/context.pl?source=$source;line=$unit_source[$source_unit_id]{LOCUS}\">";

		# here we print the unit by alternating @space and @display
		# the loop variable is the position in the unit

		for (0..$#{$unit_source[$source_unit_id]{WORD}}) {

			# here we get the word_id from its position in the phrase
			
			my $source_word_id = ${$unit_source[$source_unit_id]{WORD}}[$_];
			
			# print the interword material
			
			print XML ${$unit_source[$source_unit_id]{SPACE}}[$_];
			
			# if marked, then add an xml tag
			
			if (defined $marked_source{$source_word_id}) { print XML '<span class="marked">' }

			# print the display copy of the word
			
			print XML $display_source[$source_word_id];
			
			# close the tag if necessary
			
			if (defined $marked_source{$source_word_id}) { print XML '</span>' }
		}

		print XML ${$unit_source[$source_unit_id]{SPACE}}[-1];
		print XML "</phrase>\n";
		
		# same as above, for the target now
		
		print XML "\t\t<phrase text=\"target\" work=\"$abbr{$target}\" "
				. "line=\"$unit_target[$target_unit_id]{LOCUS}\" "
				. "link=\"$url_cgi/context.pl?source=$target;line=$unit_target[$target_unit_id]{LOCUS}\">";

		for (0..$#{$unit_target[$target_unit_id]{WORD}}) {

			my $target_word_id = ${$unit_target[$target_unit_id]{WORD}}[$_];
			
			print XML ${$unit_target[$target_unit_id]{SPACE}}[$_];
			
			if (defined $marked_target{$target_word_id}) { print XML '<span class="marked">' }
			print XML $display_target[$target_word_id];
			if (defined $marked_target{$target_word_id}) { print XML '</span>' }
		}

		print XML ${$unit_target[$target_unit_id]{SPACE}}[-1];		
		print XML "</phrase>\n";

		print XML "\t</tessdata>\n";

	}
}

# finish off the xml doc

print XML "</results>\n";

#
# redirect browser to the xml results
#

my $redirect = "$url_cgi/get-data.pl?session=$session;sort=target";

if ($quiet == 1)
{
	if ($output eq "html")
	{

		print <<END;

   <meta http-equiv="Refresh" content="0; url='$redirect'">
</head>
<body>
   <p>
      Please wait for your results until the page loads completely.  
      <br/>
      If you are not redirected automatically, 
      <a href="$redirect">click here</a>.
   </p>
</body>
</html>

END

	}
}
else
{
	if ( $output eq "cmdline" )
	{
		print STDERR "\n";
	}
	elsif ( $output eq "html")
	{
		print <<END;

	<p>Your results are done.  <a href="$redirect">Click here</a>.</p>
</body>
</html>

END

	}
}


