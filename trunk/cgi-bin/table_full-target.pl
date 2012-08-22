#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

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

if ( $output eq "html")
{
	my $query = new CGI || die "$!";
	
	$source		= $query->param('source') || "";
	$target		= $query->param('target') || "";
	$unit     	= $query->param('unit')   || "line";
	$feature		= $query->param('feature')		|| "stem";
	$stopwords	= $query->param('stoplist')	|| 10;
	
	if ($source eq "" or $target eq "")
	{
		die "read_table.pl called from web interface with no source/target";
	}
}
else
{
	
	$quiet = 0;
	
	my @text;
	
	$feature = "word";
	$unit		= "line";
	$stopwords = 10;
	
	for (@ARGV)
	{
		if 	( /--word/ )			{ $feature = 'word' }
		elsif ( /--stem/ )			{ $feature = 'stem' }
		elsif ( /--line/ )			{ $unit = 'line' }
		elsif ( /--phrase/ )			{ $unit = 'phrase' }
		elsif	( /--session=(\w+)/)	{ $session = $1 }
		else
		{
			unless (/^--/)
		{
				push @text, $_;
		}
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

my @stoplist = @{$top{$lang{$target} . '_' . $feature}};

if ($stopwords > 0)
{
	@stoplist = @stoplist[0..$stopwords-1];
}
else
{
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

my @unit_source = @{ retrieve( "$fs_data/v3/$lang{$source}/word/$source.${unit}" ) };
my @loc_source =  @{ retrieve( "$fs_data/v3/$lang{$source}/word/$source.loc_${unit}" ) };

my %index_source_ext = %{ retrieve( "$fs_data/v3/$lang{$source}/$feature/$source.index_${unit}_ext" ) };
my %index_source_int = %{ retrieve( "$fs_data/v3/$lang{$source}/$feature/$source.index_${unit}_int" ) };

if ($output ne "html")
{
	print STDERR "reading target data\n";
}

my @word = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.word" )};

my @unit_target = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.${unit}" ) };
my @loc_target  = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.loc_${unit}" ) };

my %index_target_ext = %{ retrieve( "$fs_data/v3/$lang{$target}/$feature/$target.index_${unit}_ext" ) };
my %index_target_int = %{ retrieve( "$fs_data/v3/$lang{$target}/$feature/$target.index_${unit}_int" ) };

my @phrase_lines	= @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.phrase_lines" )};

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

my @links;
my @score;

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
my $end_point = scalar(keys %index_target_ext);

# start with each key in the target

for my $key (sort keys %index_target_ext)
{
	# advance the progress bar
	
	$progress++;
	
	if ($quiet == 0)
	{
		if ($progress/$end_point > $last_progress+.025)
		{
			if ($output eq "html")
			{
				my $percent_done = sprintf("%i%%", 100*$progress/$end_point);
				print "<p>$percent_done done</p>\n";
			}
			else
			{
				print STDERR ".";
			}
			$last_progress = $progress/$end_point;
		}
	}
	
	# skip key if it doesn't exist in the source doc
	
	next unless ( defined $index_source_ext{$key} );
	
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
			
			${$match_target[$target_ref_ext]}{$source_ref_ext}{$target_ref_int} += 
				( defined $freq{$key} ? 1/$freq{$key} : 0 );
			${$match_source[$target_ref_ext]}{$source_ref_ext}{$source_ref_int} +=
				( defined $freq{$key} ? 1/$freq{$key} : 0 );
		}
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
$end_point = $#match_target;

# now look at the matches one by one, according to unit id in the target

for my $target_ref_ext (0..$#match_target)
{
	
# advance the progress bar
	
	$progress++;
	
	if ($quiet == 0)
	{
		if ($progress/$end_point > $last_progress+.025)
		{
			if ($output eq "html")
			{
				my $percent_done = sprintf("%i%%", 100*$progress/$end_point);
				print "<p>$percent_done done</p>\n";
			}
			else
			{
				print STDERR ".";
			}
			$last_progress = $progress/$end_point;
		}
	}
	
	# skip anything that doesn't have a match in the source
	
	next unless defined ($match_target[$target_ref_ext]);
	
	# look at all the source units where the feature occurs
	# sort in numerical order
	
	for my $source_ref_ext ( sort {$a <=> $b} keys %{$match_target[$target_ref_ext]})
	{
		
		# skip any match that doesn't involve two shared features in each text
		
		next if ( scalar( keys %{$match_target[$target_ref_ext]{$source_ref_ext}} ) < 2);
		next if ( scalar( keys %{$match_source[$target_ref_ext]{$source_ref_ext}} ) < 2);
				
		#
		# here's the place where a scoring algorithm should be
		#
		# - right now we have a placeholder that's a function
		#   of word frequency and distance between words
		
		my $score;
		my $distance;
		my $last_val = -1;
		
		# examine each shared term in the target in order by position
		# within the line
		
		for my $target_ref_int ( sort {$a <=> $b} keys %{$match_target[$target_ref_ext]{$source_ref_ext}} )
		{
						
			# add the distance between this and the previous term
			
			unless ($last_val == -1)
			{
				$distance += ($target_ref_int - $last_val);
			}
			$last_val = $target_ref_int;
			
			# add the frequency score for this term
			
			$score += $match_target[$target_ref_ext]{$source_ref_ext}{$target_ref_int};
			
			push @{ $links[${$unit_target[$target_ref_ext]{WORD}}[$target_ref_int]] }, $source_ref_ext;
		}
				
		#
		# now examine each shared term in the source as above
		#
		
		# reinitialize the last-term position
		
		$last_val = -1;
		
		# go through the terms in order by position
		
		for my $source_ref_int ( sort {$a <=> $b} keys %{$match_source[$target_ref_ext]{$source_ref_ext}} )
		{
			
			# add the distance between this and the previous term
			
			unless ($last_val == -1)
			{
				$distance += ($source_ref_int - $last_val);
			}
			$last_val = $source_ref_int;
			
			# add the frequency score for this term
			
			$score += $match_source[$target_ref_ext]{$source_ref_ext}{$source_ref_int};
		}
		
		# this multiplier puts the score into an easier range to read

		$score = sprintf("%i", log($score*1000));

		my @lines_affected;
		
		if ($unit eq "line")	{ $lines_affected[0] = $target_ref_ext }
		else					{ @lines_affected	 = @{$phrase_lines[$target_ref_ext]} }
		
		for (@lines_affected)	{ $score[$_]++ }
	}
}

if ($quiet == 0 and $output ne "html")
{
	print STDERR "\n";
}

# write output

if ($output ne "html")
{
	print STDERR "writing XML output";
}

# this line should ensure that the xml output is encoded utf-8

binmode XML, ":utf8";

# get the line database if we haven't already

if ($unit eq "phrase")
{
	@unit_target = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.line" ) };
	@loc_target  = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.loc_line" ) };
}

# format the stoplist

my $commonwords = join(", ", @stoplist);

# print the xml doc header

print XML <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" sessionID="$session">
<comments>Test results from Big Table</comments>
<commonwords>$commonwords</commonwords>

END

for my $ref_ext (0..$#unit_target)
{
	my $display;
	
	for my $i (0..$#{$unit_target[$ref_ext]{WORD}})
	{
		my $w = ${$unit_target[$ref_ext]{WORD}}[$i];
			
		my @links_;
		for (@{$links[$w]})
		{ 
			push @links_, $loc_source[$_]
		}
		
		my $links = join("; ", @links_);
		
		my $word_ = $word[$w];
		
		if ($links ne "") 
		{ 
			$word_ = "<link ref=\"$links\">$word_</link>";
		}
		
		$display .= ${$unit_target[$ref_ext]{SPACE}}[$i] . $word_;
	}
	
	$display .= ${$unit_target[$ref_ext]{SPACE}}[$#{$unit_target[$ref_ext]{SPACE}}];
	
	my $score = $score[$ref_ext] || 0;
	
	print XML "<l n=\"$loc_target[$ref_ext]\" score=\"$score\">$display</l>\n";
}


# finish off the xml doc

print XML "</results>\n";

#
# redirect browser to the xml results
#

my $redirect = "$url_cgi/get-data.pl?session=$session;sort=fulltext";

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

sub beta_to_uni
{
	
	my @text = @_;
	
	for (@text)
	{
		
		s/(\*)([^a-z ]+)/$2$1/g;
		
		s/\)/\x{0313}/ig;
		s/\(/\x{0314}/ig;
		s/\//\x{0301}/ig;
		s/\=/\x{0342}/ig;
		s/\\/\x{0300}/ig;
		s/\+/\x{0308}/ig;
		s/\|/\x{0345}/ig;
	
		s/\*a/\x{0391}/ig;	s/a/\x{03B1}/ig;  
		s/\*b/\x{0392}/ig;	s/b/\x{03B2}/ig;
		s/\*g/\x{0393}/ig; 	s/g/\x{03B3}/ig;
		s/\*d/\x{0394}/ig; 	s/d/\x{03B4}/ig;
		s/\*e/\x{0395}/ig; 	s/e/\x{03B5}/ig;
		s/\*z/\x{0396}/ig; 	s/z/\x{03B6}/ig;
		s/\*h/\x{0397}/ig; 	s/h/\x{03B7}/ig;
		s/\*q/\x{0398}/ig; 	s/q/\x{03B8}/ig;
		s/\*i/\x{0399}/ig; 	s/i/\x{03B9}/ig;
		s/\*k/\x{039A}/ig; 	s/k/\x{03BA}/ig;
		s/\*l/\x{039B}/ig; 	s/l/\x{03BB}/ig;
		s/\*m/\x{039C}/ig; 	s/m/\x{03BC}/ig;
		s/\*n/\x{039D}/ig; 	s/n/\x{03BD}/ig;
		s/\*c/\x{039E}/ig; 	s/c/\x{03BE}/ig;
		s/\*o/\x{039F}/ig; 	s/o/\x{03BF}/ig;
		s/\*p/\x{03A0}/ig; 	s/p/\x{03C0}/ig;
		s/\*r/\x{03A1}/ig; 	s/r/\x{03C1}/ig;
		s/s\b/\x{03C2}/ig;
		s/\*s/\x{03A3}/ig; 	s/s/\x{03C3}/ig;
		s/\*t/\x{03A4}/ig; 	s/t/\x{03C4}/ig;
		s/\*u/\x{03A5}/ig; 	s/u/\x{03C5}/ig;
		s/\*f/\x{03A6}/ig; 	s/f/\x{03C6}/ig;
		s/\*x/\x{03A7}/ig; 	s/x/\x{03C7}/ig;
		s/\*y/\x{03A8}/ig; 	s/y/\x{03C8}/ig;
		s/\*w/\x{03A9}/ig; 	s/w/\x{03C9}/ig;
	
	}

	return wantarray ? @text : $text[0];
}
