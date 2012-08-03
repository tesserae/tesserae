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

use CGI qw/:standard/;

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

#
# usage
#

my $usage = <<END;

   usage: read_table.pl --source SOURCE --target TARGET [options]

	where options are
	
	   --feature   word|stem|syn   = feature set to match on.  default is "stem".
	   --unit      line|phrase     = textual units to match.   default is "line".
	   --stopwords 0..250          = number of stopwords.      default is 10.
	
	   --no-cgi		= run from terminal not web interface
	   --quiet      = do not print progress info to stderr

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
# - choice is 'word' or 'stem'

my $feature = "stem";

# stopwords is the number of words on the stoplist

my $stopwords = 10;

# stoplist_basis is where we draw our feature
# frequencies from: source, target, or corpus

my $stoplist_basis = "corpus";

# output file

my $file_results = "tesresults.bin";

# session id

my $session = "NA";

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

# print debugging messages to stderr?

my $quiet = 0;

# maximum distance between matching tokens

my $max_dist = 999;

# metric for measuring distance

my $distance_metric = "span";

# passthrough to check_recall.pl?

my $check_recall = 0;

GetOptions( 
			'source=s'     => \$source,
			'target=s'     => \$target,
			'unit=s'       => \$unit,
			'feature=s'    => \$feature,
			'stopwords=i'  => \$stopwords, 
			'stbasis=s'    => \$stoplist_basis,
			'binary=s'     => \$file_results,
			'distance=i'   => \$max_dist,
			'dibasis=s'    => \$distance_metric,
			'quiet'        => \$quiet );


# html header
#
# put this stuff early on so the web browser doesn't
# give up

unless ($no_cgi) {

	print header();

	my $stylesheet = catfile($url_css, "style.css");

	print <<END;

<html>
<head>
	<title>Tesserae results</title>
   <link rel="stylesheet" type="text/css" href="$stylesheet" />

END

	#
	# determine the session ID
	# 

	# open the temp directory
	# and get the list of existing session files

	opendir(my $dh, $fs_tmp) || die "can't opendir $fs_tmp: $!";

	my @tes_sessions = grep { /^tesresults-[0-9a-f]{8}\.xml/ && -f catfile($fs_tmp, $_) } readdir($dh);

	closedir $dh;

	# sort them and get the id of the last one

	@tes_sessions = sort(@tes_sessions);

	$session = $tes_sessions[-1];

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

	$file_results = catfile($fs_tmp, "tesresults-$session.bin");
}

#
# abbreviations of canonical citation refs
#

my $file_abbr = catfile($fs_data, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# $lang sets the language of input texts
# - necessary for finding the files, since
#   the tables are separate.
# - one day, we'll be able to set the language
#   for the source and target independently
# - choices are "grc" and "la"

my $file_lang = catfile($fs_data, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# if web input doesn't seem to be there, 
# then check command line arguments

if ($no_cgi) {

	unless (defined ($source and $target)) {

		print STDERR $usage;
		exit;
	}
}
else {

	$source		= $query->param('source')   || "";
	$target		= $query->param('target') 	 || "";
	$unit     	= $query->param('unit') 	 || $unit;
	$feature	   = $query->param('feature')	 || $feature;
	$stopwords	= defined($query->param('stoplist')) ? $query->param('stoplist') : $stopwords;
	$stoplist_basis = $query->param('stbasis') || $stoplist_basis;
	$max_dist   = $query->param('dist') || $max_dist;
	$distance_metric = $query->param('dibasis') || $distance_metric;
	$check_recall = $query->param('check_recall') || $check_recall;
	
	if ($source eq "" or $target eq "") {
	
		die "read_table.pl called from web interface with no source/target";
	}
	
	$quiet = 1;
	
}

unless ($quiet) {

	print STDERR "target=$target\n";
	print STDERR "source=$source\n";
	print STDERR "lang=$lang{$target};\n";
	print STDERR "feature=$feature\n";
	print STDERR "unit=$unit\n";
	print STDERR "stopwords=$stopwords\n";
	print STDERR "stoplist basis=$stoplist_basis\n";
	print STDERR "max_dist=$max_dist\n";
	print STDERR "distance basis=$distance_metric\n";
}


#
# calculate feature frequencies
#

# token frequencies from the target text

my $file_freq_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_word');

my %freq_target = %{retrieve( $file_freq_target)};

# token frequencies from the target text

my $file_freq_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_word');

my %freq_source = %{retrieve( $file_freq_source)};

#
# basis for stoplist is feature frequency from one or both texts
#

my @stoplist = @{load_stoplist($stoplist_basis, $stopwords)};

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
		my $distance = dist(\%{$match{$unit_id_target}{$unit_id_source}}, $distance_metric);
		
		# examine each shared term in the target in order by position
		# within the line
		
		for my $token_id_target (@{$match{$unit_id_target}{$unit_id_source}{TARGET}} ) {
						
			# mark the display copy as matched

			$marked_target{$token_id_target} = 1;
						
			# add the frequency score for this term
			
			$score += 1/$freq_target{$token_target[$token_id_target]{FORM}};
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

			$score += 1/$freq_source{$token_source[$token_id_source]{FORM}};
		}
		
		if ($distance > $max_dist) {
			
			delete $match{$unit_id_target}{$unit_id_source};
			next;
		}
		
		$score = sprintf("%i", log($score / $distance));
		
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
# write binary results
#

if ($file_results ne "none") {

	$match{META} = {

		SOURCE    => $source,
		TARGET    => $target,
		UNIT      => $unit,
		FEATURE   => $feature,
		STOPLIST  => [@stoplist],
		STBASIS   => $stoplist_basis,
		DIST      => $max_dist,
		DIBASIS   => $distance_metric,
		SESSION   => $session,
		COMMENT   => $feature_notes{$feature},
		TOTAL     => $total_matches
	};

	unless ($quiet) {
		
		print STDERR "writing $file_results\n";
	}
	
	nstore \%match, $file_results;
}


#
# redirect browser to results
#

my $redirect;

if ($check_recall) {

	$redirect = "$url_cgi/check-recall.pl?session=$session;sort=target";
}
else {

	$redirect = "$url_cgi/read_bin.pl?session=$session;sort=target";
}

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


#
# subroutines
#

#
# dist : calculate the distance between matching terms
#
#   used in determining match scores
#   and in filtering out bad results

sub dist {

	my ($match_ref, $metric) = @_[0,1];
	
	my %match = %$match_ref;
	
	my $dist;
	
	if ($metric eq "span") {
	
		$dist  = abs($match{TARGET}[-1] - $match{TARGET}[0]);
		$dist += abs($match{SOURCE}[-1] - $match{SOURCE}[0]);
	}
	elsif ($metric eq "span-target") {
		
		$dist = abs($match{TARGET}[-1] - $match{TARGET}[0]);
	}
	elsif ($metric eq "span-source") {
		
		$dist = abs($match{SOURCE}[-1] - $match{SOURCE}[0]);
	}
	elsif ($metric eq "freq") {
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @{$match{TARGET}}; 
			
		$dist  = abs($t[0] - $t[1]);

		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @{$match{SOURCE}}; 
		
		$dist += abs($s[0] - $s[1]);
	}
	elsif ($metric eq "freq-target") {
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @{$match{TARGET}}; 
			
		$dist  = abs($t[0] - $t[1]);
	}
	elsif ($metric eq "freq-source") {
		
		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @{$match{SOURCE}}; 
		
		$dist = abs($s[0] - $s[1]);
	}
	
	return $dist;
}

sub load_stoplist {

	my ($stoplist_basis, $stopwords) = @_[0,1];
	
	my %basis;
	my @stoplist;
	
	if ($stoplist_basis eq "target") {
		
		my $file = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_' . $feature);
		
		%basis = %{retrieve($file)};
	}
	
	elsif ($stoplist_basis eq "source") {
		
		my $file = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_' . $feature);

		%basis = %{retrieve($file)};		
	}
	
	elsif ($stoplist_basis eq "corpus") {

		my $file = catfile($fs_data, 'common', $lang{$target} . '.' . $feature . '.freq');
		
		%basis = %{retrieve($file)};
	}
	
	elsif ($stoplist_basis eq "both") {
		
		my $file_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_' . $feature);
		
		%basis = %{retrieve($file_target)};
		
		my $file_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_' . $feature);
		
		my %basis2 = %{retrieve($file_source)};
		
		for (keys %basis2) {
		
			if (defined $basis{$_}) {
			
				$basis{$_} = ($basis{$_} + $basis2{$_})/2;
			}
			else {
			
				$basis{$_} = $basis2{$_};
			}
		}
	}
		
	@stoplist = sort {$basis{$b} <=> $basis{$a}} keys %basis;
	
	if ($stopwords > 0) {
		
		@stoplist = @stoplist[0..$stopwords-1];
	}
	else {
		
		@stoplist = ();
	}

	return \@stoplist;
}
