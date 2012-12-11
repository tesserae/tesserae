#! /opt/local/bin/perl5.12

=head1 NAME

read_table.pl - Perform a Tesserae search.

=head1 SYNOPSIS

B<read_table.pl> B<--target> I<target_text> B<--source_text> I<source> [B<--unit> I<unit>] [B<--feature> I<feature>] [B<--stop> I<stoplist_size>] [B<--stbasis> I<stoplist_basis>] [B<--distance> I<max_dist>] [B<--dibasis> I<distance_basis>] [B<--cutoff> I<score_cutoff>] [B<--interest> I<max_freq>] [B<--binary> I<file>] [B<--quiet>]

=head1 DESCRIPTION

This script compares two texts in the Tesserae corpus and returns a list of "parallels", pairs of textual units which share common features.  These parallels are kept in a hash which is saved as a Storable binary.  This results file can be read and formatted in a user-friendly way with the companion script I<read_bin.pl>.

This script is primarily called as a cgi executable from the web interface.  It creates a new session id for the results and saves them to the Tesserae I<tmp/> directory.  It then redirects the browser to I<read_bin.pl> which mediates viewing the results.

It can also be run from the command line.  In this case, the results are written to a user specified file.

The names of the source and target texts to be searched must be specified.  B<Target> means the alluding (more recent) text.  B<Source> is the alluded-to (earlier) text.

The name of a text is identical to its filename without the C<.tess> extension.  For example, our benchmark test is to search for allusions to Vergil's Aeneid in Book 1 of Lucan's Pharsalia.  The file containing the Aeneid is I<texts/la/vergil.aeneid.tess> and that containing just the first book of Pharsalia is I<texts/la/lucan.pharsalia/lucan.pharsalia.part.1.tess>.  Thus, a default search, taking Lucan as the alluder and Vergil as the alluded-to, is run like this:

% cgi-bin/read_table.pl --source vergil.aeneid --target lucan.pharsalia.part.1

=head1 OPTIONS 

=over

=item B<--unit> line|phrase

I<unit> specifies the textual units to be compared.  Choices currently are B<line> (the default) which compares verse lines or B<phrase>, which compares grammatical phrases.  For now we assume that the punctuation marks [.;:?] delimit phrases.

=item B<--feature> word|stem|syn 

This specifies the features set to match against.  B<word> only allows matches on forms that are identical. B<stem> (the default), allows matches on any inflected form of the same stem. B<syn> matches not only forms of the same headword but also other headwords taken to be related in meaning.  B<stem> and B<syn> only work if the appropriate dictionaries are installed; neither will work on English texts, and B<syn> won't work on Greek.

=item B<--stop> I<stoplist_size>

I<stoplist_size> is the number of stop words (stems, etc.) to use.  Matches on any of these are excluded from results.  The stop list is calculated by ordering all the features (see above) in the stoplist basis (see below) by frequency and taking the top I<N>, where I<N>=I<stoplist_size>.  The default is 10, I think.

=item B<--stbasis> corpus|target|source|both

Stoplist basis is a string indicating the source for the ranked list of features from which the stoplist is taken.  B<corpus> (the default) derives the stoplist from the entire corpus; B<source>, uses only the source; B<target>, only the target; and B<both> uses the source and target but nothing else.

=item B<--dist> I<max_dist>

This sets the maximum distance between matching words.  For two units (one in the source and one in the target) to be considered a match, each must have at least two words common to the other (regardless of the feature on which they matched).  It's generally true that in good allusions these words are close together in both units.  Setting the maximum distance to I<N> means that matches where either unit's matching words are more than I<N> tokens apart will be excluded. The default distance is 999, which is presumably equivalent to setting no limit.

=item B<--dibasis> span|span-target|span-source|freq|freq-target|freq-source

Distance basis is a string indicating the way to calculate the distance between matching words in a parallel (matching pair of units).  The default is B<span>, which adds together the distance in tokens between the two farthest-apart words in each phrase.  Related to this are B<span-target> which uses the distance between the two farthest-apart words in the target unit only, and B<span-source> which uses the two farthest-apart words in the source unit.  An alternative basis is B<freq>, which uses the distance between the two words with the lowest frequencies (in their own text only), adding the frequency-based distances of the target and source units together.  As for B<span>, you can select the frequency-based distance in only one text with B<freq-target> or B<freq-source>.

=item B<--cutoff> I<score_cutoff>

Each match found by Tesserae is given a score.  Setting a cutoff will cause any match with a score less than this to be dropped from the results.  Default is 0 (presumably equivalent to no cutoff).

=item B<--interest> I<max_freq>

This is a threshold defining the maximum frequency of "interesting" words.  This is still experimental; in a default installation it's not used.

=item B<--binary> I<file>

This is the name of the output file.  The Storable binary containing your results as a big hash will be saved here.  The default is I<results.bin>.

=item B<--quiet>

Don't write progress info to STDERR.

=back

The values of all these options should be printed to STDERR when you run the script from the command-line, and should also be saved with the results.

=head1 KNOWN BUGS

The distance between two words includes punctuation and space tokens as well as word tokens, so that I<max_dist> is probably about twice what you think it should be.

=head1 SEE ALSO

I<cgi-bin/read_table.pl>

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is read_table.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Neil Coffee, Chris Forstall, James Gawley.

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

my $t0 = time;

use strict;
use warnings;

use CGI qw/:standard/;

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);

use TessSystemVars;
use EasyProgressBar;

#
# usage
#

my $usage = <<END;

   usage: read_table.pl --source SOURCE --target TARGET [options]

   options:
	   --feature   word|stem|syn
                       the feature set to match on. default is "stem".
	   --unit      line|phrase
                       textual units to match. default is "line".
	   --stopwords 0..250
                       the number of stopwords. default is 10.
	   --distance  0..999
                       max distance between match words. default is 999.
	   --stbasis   corpus|target|source|both
	               basis for choosing stop words. default is "corpus".
	   --dibasis   span|freq
                       basis for calculating distance between matching
                       words. default is "span".
       --bin FILENAME
                       specify output file name. default is "tesresults.bin"	
	   --quiet     do not print progress info to stderr.

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

# apply the scoring team filter?

my $filter = 0;

# minimium frequency for interesting words

my $interest = 0.008;

# output file

my $file_results = "tesresults";

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

my $distance_metric = "freq";

# filter results below a certain score

my $cutoff = 0;

# filter multi-results if passing off to multitext.pl

my $multi_cutoff = 0;                  

# text list to pass on to multitext.pl

my @include;

# which script should mediate the display of results

my $frontend = 'default';
my %redirect;

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
			'cutoff=f'     => \$cutoff,
			'filter'       => \$filter,
			'interest=f'   => \$interest,
			'quiet'        => \$quiet );

# html header
#
# put this stuff early on so the web browser doesn't
# give up

unless ($no_cgi) {

	print header();

	my $stylesheet = "$url_css/style.css";

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

	my @tes_sessions = grep { /^tesresults-[0-9a-f]{8}/ && -d catfile($fs_tmp, $_) } readdir($dh);

	closedir $dh;

	# sort them and get the id of the last one

	@tes_sessions = sort(@tes_sessions);

	$session = $tes_sessions[-1];

	# then add one to it;
	# if we can't determine the last session id,
	# then start at 0

	if (defined($session)) {

	   $session =~ s/^.+results-//;
	}
	else {

	   $session = "0"
	}

	# put the id into hex notation to save space and make it look confusing

	$session = sprintf("%08x", hex($session)+1);

	# open the new session file for output

	$file_results = catfile($fs_tmp, "tesresults-$session");
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

	$source          = $query->param('source')       || "";
	$target          = $query->param('target')       || "";
	$unit            = $query->param('unit')         || $unit;
	$feature         = $query->param('feature')      || $feature;
	$stopwords       = defined($query->param('stopwords')) ? $query->param('stopwords') : $stopwords;
	$stoplist_basis  = $query->param('stbasis')      || $stoplist_basis;
	$max_dist        = $query->param('dist')         || $max_dist;
	$distance_metric = $query->param('dibasis')      || $distance_metric;
	$cutoff          = $query->param('cutoff')       || $cutoff;
	$filter          = defined($query->param('filter')) ? $query->param('filter') : $filter;
	$interest        = $query->param('interest')     || $interest;
	$frontend        = $query->param('frontend')     || $frontend;
	$multi_cutoff    = $query->param('mcutoff')      || $multi_cutoff;
	@include         = $query->param('include');
	
	if ($source eq "" or $target eq "") {
	
		die "read_table.pl called from web interface with no source/target";
	}
	
	$quiet = 1;
	
	# how to redirect browser to results

	%redirect = ( 
		default  => "$url_cgi/read_bin.pl?session=$session",
		recall   => "$url_cgi/check-recall.pl?session=$session",
		fulltext => "$url_cgi/fulltext.pl?session=$session",
		multi    => "$url_cgi/multitext.pl?session=$session;mcutoff=$multi_cutoff"
		         . join("", map {";include=$_"} @include)
	);

	
	print <<END;
	<meta http-equiv="Refresh" content="0; url='$redirect{$frontend}'">
	</head>
	<body>
		<p>
			Searching...
		</p>
END
                                       


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
	print STDERR "score cutoff=$cutoff\n";
	print STDERR "interesting freq=$interest\n";
}


#
# calculate feature frequencies
#

# token frequencies from the target text

my $file_freq_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target . ".freq_score_$feature");

my %freq_target = %{retrieve( $file_freq_target)};

# token frequencies from the target text

my $file_freq_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source . ".freq_score_$feature");

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

	($max_heads, $min_similarity) = @{ retrieve(catfile($fs_data, "common", "$lang{$target}.syn.cache.param")) };
}


#
# read data from table
#


unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $file_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source);

my @token_source   = @{ retrieve("$file_source.token") };
my @unit_source    = @{ retrieve("$file_source.$unit") };
my %index_source   = %{ retrieve("$file_source.index_$feature")};

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $file_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target);

my @token_target   = @{ retrieve("$file_target.token") };
my @unit_target    = @{ retrieve("$file_target.$unit") };
my %index_target   = %{ retrieve("$file_target.index_$feature" ) };


#
#
# this is where we calculated the matches
#
#

my $t1 = time;

# this hash holds information about matching units

my %match_target;
my %match_source;
my %match_score;

#
# consider each key in the source doc
#

unless ($quiet) {

	print STDERR "comparing $target and $source\n";
}

# draw a progress bar

my $pr;

if ($no_cgi) {
	$pr = ProgressBar->new(scalar(keys %index_source), $quiet);
}
else {
	$pr = HTMLProgress->new(scalar(keys %index_source));
}

# start with each key in the source

for my $key (keys %index_source) {

	# advance the progress bar

	$pr->advance();

	# skip key if it doesn't exist in the target doc

	next unless ( defined $index_target{$key} );

	# skip key if it's in the stoplist

	next if ( grep { $_ eq $key } @stoplist);

	# link every occurrence in one text to every one in the other text

	for my $token_id_target ( @{$index_target{$key}} ) {

		my $unit_id_target = $token_target[$token_id_target]{uc($unit) . '_ID'};

		for my $token_id_source ( @{$index_source{$key}} ) {

			my $unit_id_source = $token_source[$token_id_source]{uc($unit) . '_ID'};
			
			$match_target{$unit_id_target}{$unit_id_source}{$token_id_target}{$key} = 1;
			$match_source{$unit_id_target}{$unit_id_source}{$token_id_source}{$key} = 1;
		}
	}
}

print "search>>" . (time-$t1) . "\n" if $no_cgi;

#
#
# assign scores
#
#

$t1 = time;

# how many matches in all?

my $total_matches = 0;

# draw a progress bar

if ($no_cgi) {

	print STDERR "calculating scores\n" unless $quiet;

	$pr = ProgressBar->new(scalar(keys %match_target), $quiet);
}
else {

	print "<p>Scoring...</p>\n";

	$pr = HTMLProgress->new(scalar(keys %match_target));
}

#
# look at the matches one by one, according to unit id in the target
#

for my $unit_id_target (keys %match_target) {

	# advance the progress bar

	$pr->advance();

	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $unit_id_source (keys %{$match_target{$unit_id_target}}) {
                                     
		# intra-textual matching:
		# 
		# where source and target are the same text, don't match
		# a line with itself
		
		next if ($source eq $target) and ($unit_id_source == $unit_id_target);

		#
		# remove matches having fewer than 2 matching words
		# or matching on fewer than 2 different keys
		#
			
		# check that the target has two matching words
			
		if ( scalar( keys %{$match_target{$unit_id_target}{$unit_id_source}} ) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;
		}
		
		# check that the source has two matching words
	
		if ( scalar( keys %{$match_source{$unit_id_target}{$unit_id_source}} ) < 2) {
	
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}		
	
		# make sure each phrase has at least two different inflected forms
		
		my %seen_forms;	
		
		for my $token_id_target (keys %{$match_target{$unit_id_target}{$unit_id_source}} ) {
						
			$seen_forms{$token_target[$token_id_target]{FORM}}++;
		}
		
		if (scalar(keys %seen_forms) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}	
		
		%seen_forms = ();
		
		for my $token_id_source ( keys %{$match_source{$unit_id_target}{$unit_id_source}} ) {
		
			$seen_forms{$token_source[$token_id_source]{FORM}}++;
		}

		if (scalar(keys %seen_forms) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}	
				
		#
		# calculate the distance
		# 
		
		my $distance = dist($match_target{$unit_id_target}{$unit_id_source}, $match_source{$unit_id_target}{$unit_id_source}, $distance_metric);
		
		if ($distance > $max_dist) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;
		}
		
		#
		# filter based on scoring team's algorithm
		#
		
		if ($filter and not score_team($match_target{$unit_id_target}{$unit_id_source}, $match_source{$unit_id_target}{$unit_id_source})) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}
		
		#
		# calculate the score
		#
		
		# score
		
		my $score = score_default($match_target{$unit_id_target}{$unit_id_source}, $match_source{$unit_id_target}{$unit_id_source}, $distance);
								
		if ( $score < $cutoff) {

			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}
		
		# save calculated score, matched words, etc.
		
		$match_score{$unit_id_target}{$unit_id_source} = $score;
		
		$total_matches++;
	}
}

my %feature_notes = (
	
	word => "Exact matching only.",
	stem => "Stem matching enabled.  Forms whose stem is ambiguous will match all possibilities.",
	syn  => "Stem + synonym matching.  This search is still in development.  Note that stopwords may match on less-common synonyms.  max_heads=$max_heads; min_similarity=$min_similarity"
	
	);

print "score>>" . (time-$t1) . "\n" if $no_cgi;

#
# write binary results
#

$t1 = time;

my %match_meta = (

	SOURCE    => $source,
	TARGET    => $target,
	UNIT      => $unit,
	FEATURE   => $feature,
	STOP      => $stopwords,
	STOPLIST  => [@stoplist],
	STBASIS   => $stoplist_basis,
	DIST      => $max_dist,
	DIBASIS   => $distance_metric,
	SESSION   => $session,
	CUTOFF    => $cutoff,
	FILTER    => $filter,
	INTEREST  => $interest,
	COMMENT   => $feature_notes{$feature},
	TOTAL     => $total_matches
);


if ($no_cgi) {
	
	print STDERR "writing $file_results\n" unless $quiet;
}
else {

	print "<p>Writing session data.</p>";
}

rmtree($file_results);
mkpath($file_results);
	
nstore \%match_target, catfile($file_results, "match.target");
nstore \%match_source, catfile($file_results, "match.source");
nstore \%match_score,  catfile($file_results, "match.score");
nstore \%match_meta,   catfile($file_results, "match.meta");

print "store>>" . (time-$t1) . "\n" if $no_cgi;

print <<END unless ($no_cgi);

	<p>
      Your search is done.  If you are not redirected automatically, 
      <a href="$redirect{$frontend}">click here</a>.
	</p>
</body>
</html>

END


print "total>>" . (time-$t0)  . "\n" if $no_cgi;

#
# subroutines
#

#
# dist : calculate the distance between matching terms
#
#   used in determining match scores
#   and in filtering out bad results

sub dist {

	my ($match_t_ref, $match_s_ref, $metric) = @_;
	
	my %match_target = %$match_t_ref;
	my %match_source = %$match_s_ref;
	
	my @target_id = sort {$a <=> $b} keys %match_target;
	my @source_id = sort {$a <=> $b} keys %match_source;
	
	my $dist = 0;
	
	#
	# distance is calculated by one of the following metrics
	#
	
	# freq: count all words between (and including) the two lowest-frequency 
	# matching words in each phrase.  NB this is the best metric in my opinion.
	
	if ($metric eq "freq") {
	
		# sort target token ids by frequency of the forms
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @target_id; 
			      
		# consider the two lowest;
		# put them in order from left to right
			      
		if ($t[0] > $t[1]) { @t[0,1] = @t[1,0] }
			
		# now go token to token between them, incrementing the distance
		# only if each token is a word.
			
		for ($t[0]..$t[1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
			
		# now do the same in the source phrase
			
		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @source_id; 
		
		if ($s[0] > $s[1]) { @s[0,1] = @s[1,0] }
			
		for ($s[0]..$s[1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# freq_target: as above, but only in the target phrase
	
	elsif ($metric eq "freq_target") {
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @target_id; 
			
		if ($t[0] > $t[1]) { @t[0,1] = @t[1,0] }
			
		for ($t[0]..$t[1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
	}
	
	# freq_source: ditto, but source phrase only
	
	elsif ($metric eq "freq_source") {
		
		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @source_id; 
		
		if ($s[0] > $s[1]) { @s[0,1] = @s[1,0] }
			
		for ($s[0]..$s[1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span: count all words between (and including) first and last matching words
	
	elsif ($metric eq "span") {
	
		# check all tokens from the first (lowest-id) matching word
		# to the last.  increment distance only if token is of type WORD.
	
		for ($target_id[0]..$target_id[-1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
		
		for ($source_id[0]..$source_id[-1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span_target: as above, but in the target only
	
	elsif ($metric eq "span_target") {
		
		for ($target_id[0]..$target_id[-1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span_source: ditto, but source only
	
	elsif ($metric eq "span_source") {
		
		for ($source_id[0]..$source_id[-1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
		
	return $dist;
}

sub load_stoplist {

	my ($stoplist_basis, $stopwords) = @_[0,1];
	
	my %basis;
	my @stoplist;
	
	if ($stoplist_basis eq "target") {
		
		my $file = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_stop_' . $feature);
		
		%basis = %{retrieve($file)};
	}
	
	elsif ($stoplist_basis eq "source") {
		
		my $file = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_stop_' . $feature);

		%basis = %{retrieve($file)};		
	}
	
	elsif ($stoplist_basis eq "corpus") {

		my $file = catfile($fs_data, 'common', $lang{$target} . '.' . $feature . '.freq');
		
		%basis = %{retrieve($file)};
	}
	
	elsif ($stoplist_basis eq "both") {
		
		my $file_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target . '.freq_stop_' . $feature);
		
		%basis = %{retrieve($file_target)};
		
		my $file_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source . '.freq_stop_' . $feature);
		
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
		
		if ($stopwords > scalar(@stoplist)) { $stopwords = scalar(@stoplist) }
		
		@stoplist = @stoplist[0..$stopwords-1];
	}
	else {
		
		@stoplist = ();
	}

	return \@stoplist;
}

sub exact_match {

	my ($ref_target, $ref_source) = @_[0,1];

	my @target_id = keys %$ref_target;
	my @source_id = keys %$ref_source;
	
	my @ttokens;
	my @stokens;
		
	for (@target_id) {
	
		push @ttokens, $token_target[$_]{FORM};
	}
	
	for (@source_id) {
		push @stokens, $token_source[$_]{FORM};
	}
	
	@ttokens = @{TessSystemVars::uniq(\@ttokens)};
	@stokens = @{TessSystemVars::uniq(\@ttokens)};
	
	my @exact_match = @{TessSystemVars::intersection(\@ttokens, \@stokens)};
	
	return scalar(@exact_match);
}

sub score_default {
	
	my ($match_t_ref, $match_s_ref, $distance) = @_;

	my %match_target = %$match_t_ref;
	my %match_source = %$match_s_ref;
	
	my $score = 0;
		
	for my $token_id_target (keys %match_target ) {
									
		# add the frequency score for this term
		
		$score += 1/$freq_target{$token_target[$token_id_target]{FORM}};
	}
	
	for my $token_id_source ( keys %match_source ) {

		# add the frequency score for this term

		$score += 1/$freq_source{$token_source[$token_id_source]{FORM}};
	}
	
	$score = sprintf("%.3f", log($score/$distance**2));
	
	return $score;
}

sub score_team {

	# the parallel to check
	
	my ($match_t_ref, $match_s_ref) = @_;

	my %match_target = %$match_t_ref;
	my %match_source = %$match_s_ref;
	
	# count interesting words in three categories
	
	my @cat   = (0, 0, 0);
	my @level = (0.0004, 0.0008, 0.0018);
	
	# start with a "reject" policy
	
	my $score = 0;
	
	# check all the tokens in the target phrase
	
	for my $token_id_target (keys %match_target ) {
		
		for (0..2) {
		
			if ($freq_target{$token_target[$token_id_target]{FORM}} < $level[$_]) {
			
				$cat[$_]++;
			}
		}
	}
	
	# and the source phrase
	
	for my $token_id_source ( keys %match_source ) {
		
		for (0..2) {
		
			if ($freq_source{$token_source[$token_id_source]{FORM}} < $level[$_]) { 
			
				$cat[$_]++; 
			}
		}
	}
	
	# get the number of exact matches
	
	my $exact_match = exact_match(\%match_target, \%match_source);
	
	# promote parallel to "keep" if it meets the criteria
	
	if (($cat[2] > 0) or ($cat[1] > 1) or ($cat[0] > 0 and $exact_match > 0 ))  {

		$score = 1;
	}
	
	return $score;
}
