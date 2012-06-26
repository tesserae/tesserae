#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

use strict;
use warnings;

use Getopt::Long;
use Storable qw(nstore retrieve);

use TessSystemVars;
use EasyProgressBar;

#
# usage
#

my $usage = "usage: read_table.pl --source SOURCE --target TARGET [--feature FEATURE] [--unit UNIT] [--stopwords N] [--no-cgi] [--quiet]\n";

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
# - choice is 'word' or 'stem'

my $feature = "stem";

# stopwords is the number of words on the stoplist

my $stopwords = 10;

# is the program being run from the web or
# from the command line?

my $no_cgi = 0;

# print debugging messages to stderr?

my $quiet = 0;


GetOptions( 'source=s'	=> \$source,
			'target=s'	=> \$target,
			'unit=s'	=> \$unit,
			'feature=s'	=> \$feature,
			'stopwords=i' => \$stopwords, 
			'no-cgi'	=> \$no_cgi,
			'quiet' 	=> \$quiet );



# html header
#
# put this stuff early on so the web browser doesn't
# give up

unless ($no_cgi) {
	
	use CGI qw/:standard/;

	print header();

	my $stylesheet = "$url_css/style.css";

	print <<END;

<html>
<head>
	<title>Tesserae results</title>
   <link rel="stylesheet" type="text/css" href="$stylesheet" />

END

}

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

if ($no_cgi)
{
	open (XML, ">&STDOUT") || die "can't write to STDOUT";
}
else
{
	open (XML, '>' . $session_file) || die "can't open " . $session_file . ':' . $!;
}

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

if ($no_cgi) {

	unless (defined ($source and $target)) {

		print STDERR $usage;
		exit;
	}
}
else
{
	my $query = new CGI || die "$!";

	$source		= $query->param('source')   || "";
	$target		= $query->param('target') 	 || "";
	$unit     	= $query->param('unit') 	 || "line";
	$feature		= $query->param('feature')	 || "stem";
	$stopwords	= defined($query->param('stoplist')) ? $query->param('stoplist') : 10;

	if ($source eq "" or $target eq "")
	{
		die "read_table.pl called from web interface with no source/target";
	}
	
	$quiet = 1;
	
	if ($unit eq "window")
	{
		my $redirect = "$url_cgi/session.pl?target=$target;source=$source;match=$feature;cutoff=$stopwords";

		print <<END;
		   <meta http-equiv="Refresh" content="0; url='$redirect'">
		</head>
		<body>
			<p>
				One moment...
			</p>
		   <p>
		      If you are not redirected automatically, 
		      <a href="$redirect">click here</a>.
		   </p>
		</body>
		</html>
END

	}
}

unless ($quiet) {

	print STDERR "target=$target\n";
	print STDERR "source=$source\n";
	print STDERR "lang=$lang{$target};\n";
	print STDERR "feature=$feature\n";
	print STDERR "unit=$unit\n";
	print STDERR "stopwords=$stopwords\n";
}


# a stop list
# - hard coded in TessSystemVars, work on this in future
# - feature-set-specific

my @stoplist = @{$top{$lang{$target} . '_' . $feature}};

if ($stopwords > 0) {
	
	@stoplist = @stoplist[0..$stopwords-1];
}
else {
	
	@stoplist = ();
}

#
# calculate feature frequencies
#

# my %freq = %{ retrieve( "$fs_data/common/$lang{$target}.${feature}.count" )};

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

my $path_source = "$fs_data/test/$lang{$source}/$source";

my @token_source   = @{ retrieve( "$path_source/$source.token"    ) };
my @unit_source    = @{ retrieve( "$path_source/$source.${unit}" ) };
my %index_source   = %{ retrieve( "$path_source/$source.index_$feature" ) };

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $path_target = "$fs_data/test/$lang{$target}/$target";

my @token_target   = @{ retrieve( "$path_target/$target.token"    ) };
my @unit_target    = @{ retrieve( "$path_target/$target.${unit}" ) };
my %index_target   = %{ retrieve( "$path_target/$target.index_$feature" ) };


#
# this is where we calculated the matches
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
# assign scores, write output
#

unless ($no_cgi) {

	print STDERR "\n";

	print STDERR "writing xml output\n";
}

# this line should ensure that the xml output is encoded utf-8

binmode XML, ":utf8";

# format the stoplist

my $commonwords = join(", ", @stoplist);

# add a featureset-specific message

my %feature_notes = (
	
	word => "Exact matching only.",
	stem => "Stem matching enabled.  Forms whose stem is ambiguous will match all possibilities.",
	syn  => "Stem + synonym matching.  This search is still in development.  Note that stopwords may match on less-common synonyms.  max_heads=$max_heads; min_similarity=$min_similarity"
	
	);

#
# print results
#

print STDERR "writing results\n";

# draw a progress bar

$pr = $quiet ? 0 : ProgressBar->new(scalar(keys %match));

# print the xml doc header

print XML <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" unit="$unit" feature="$feature" sessionID="$session">
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

		# skip any match that doesn't involve two shared features in each text
		
		next if ( scalar( @{$match{$unit_id_target}{$unit_id_source}{TARGET}} ) < 2);
		next if ( scalar( @{$match{$unit_id_target}{$unit_id_source}{SOURCE}} ) < 2);

		# this will record which words are to be marked in the display

		my %marked_source;
		my %marked_target;

		# this array will hold "matched-on" keys

		my @matched_keys_target;
		my @matched_keys_source;
		
		#
		# here's the place where a scoring algorithm should be
		#
		# - right now we have a placeholder that's a function
		#   of word frequency and distance between words
		
		my $score;
		my $distance = $match{$unit_id_target}{$unit_id_source}{TARGET}[-1] - $match{$unit_id_target}{$unit_id_source}{TARGET}[0];
		
		# examine each shared term in the target in order by position
		# within the line
		
		for my $token_id_target (@{$match{$unit_id_target}{$unit_id_source}{TARGET}} ) {
			
			# add this term to the list of shared terms
			
			push @matched_keys_target, $token_target[$token_id_target]{DISPLAY};
			
			# mark the display copy as matched

			$marked_target{$token_id_target} = 1;
						
			# add the frequency score for this term
			
			$score += 1;
		}

		#
		# now examine each shared term in the source as above
		#

		$distance += $match{$unit_id_target}{$unit_id_source}{SOURCE}[-1] - $match{$unit_id_target}{$unit_id_source}{SOURCE}[0];
		
		# go through the terms in order by position
		
		for my $token_id_source ( @{$match{$unit_id_target}{$unit_id_source}{SOURCE}} ) {

			# add the term to shared terms
			
			push @matched_keys_source, $token_source[$token_id_source]{DISPLAY};
			
			# mark the display copy

			$marked_source{$token_id_source} = 1;

			# add the frequency score for this term

			$score += 1;
		}
		
		# format the list of all unique shared words
		
		my $keypair = join(", ", @matched_keys_target, @matched_keys_source);

		# now write the xml record for this match

		print XML "\t<tessdata keypair=\"$keypair\" score=\"" . sprintf("%.2f", $score/($distance || 1)) . "\">\n";

		print XML "\t\t<phrase text=\"source\" work=\"$abbr{$source}\" "
				. "unitID=\"$unit_id_source\" "
				. "line=\"$unit_source[$unit_id_source]{LOCUS}\" "
				. "link=\"$url_cgi/context.pl?source=$source;line=$unit_source[$unit_id_source]{LOCUS}\">";

		# here we print the unit

		for my $token_id_source (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
			
			if (defined $marked_source{$token_id_source}) { print XML '<span class="matched">' }

			# print the display copy of the token
			
			print XML $token_source[$token_id_source]{DISPLAY};
			
			# close the tag if necessary
			
			if (defined $marked_source{$token_id_source}) { print XML '</span>' }
		}

		print XML "</phrase>\n";
		
		# same as above, for the target now
		
		print XML "\t\t<phrase text=\"target\" work=\"$abbr{$target}\" "
				. "unitID=\"$unit_id_target\" "
				. "line=\"$unit_target[$unit_id_target]{LOCUS}\" "
				. "link=\"$url_cgi/context.pl?source=$target;line=$unit_target[$unit_id_target]{LOCUS}\">";

		for my $token_id_target (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
			
			if (defined $marked_target{$token_id_target}) { print XML '<span class="matched">' }
			print XML $token_target[$token_id_target]{DISPLAY};
			if (defined $marked_target{$token_id_target}) { print XML '</span>' }
		}

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

print <<END unless ($no_cgi);

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
