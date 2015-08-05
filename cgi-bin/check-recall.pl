#!/usr/bin/env perl

# check-recall.pl
#
# this checks Tesserae output against a benchmark set
# previously saved as a binary using build-rec.pl
#
# its purpose is to tell you what portion of the benchmark
# allusions are present in your tesserae results.


use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}	
	
	$lib = catdir($lib, 'TessPerl');	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use CGI qw(:standard);

use Storable;
use File::Basename;
use Parallel;

# optional modules

my $stemmer;

my $usage = "usage: perl check-recall [--cache CACHE] TESRESULTS\n";

my $session;

my $process_multi = 0;
my $use_lingua_stem = 0;
my $export = 'summary';
my $sort = 'score';
my $rev = 1;

my @w = (7);
my $quiet = 1;

my %file;
my %name;

$file{cache} = catfile($fs{data}, 'bench', 'rec.cache');

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# commandline options
#

GetOptions(
	"cache=s"    => \$file{cache},
	"session=s"  => \$session,
	"sort=s"     => \$sort,
	"reverse"    => \$rev,
	"multi=i"    => \$process_multi,
	"export=s"   => \$export
	);

#
# CGI options
#

unless ($no_cgi) {
		
	# form data
		
	$session      = $query->param('session');
	$sort         = $query->param('sort')   || $sort;
	$export       = $query->param('export') || 'html';
	$rev          = $query->param('rev')    if defined $query->param('rev');
	
	my $cache = $query->param('cache');
	if ($cache) { $file{cache} = catfile($fs{data}, 'bench', $cache . ".cache")};
	
	$quiet = 1;
	
	# header
	
	my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
	
	if ($export eq "xml") { $h{'-type'} = "text/xml"; $h{'-attachment'} = "tesresults-$session.xml" }
	if ($export eq "csv") { $h{'-type'} = "text/csv"; $h{'-attachment'} = "tesresults-$session.csv" }
	if ($export eq "tab") { $h{'-type'} = "text/plain"; $h{'-attachment'} = "tesresults-$session.txt" }
	if ($export =~ /^miss/) { $h{'-type'} = "text/plain"; $h{'-attachment'} = "tesresults-$session.missed.txt" }

	print header(%h);
} 

#
# the file to read
#

if (defined $session) {

	$file{tess} = catfile($fs{tmp}, "tesresults-" . $session);
}
else {
	
	$file{tess} = shift @ARGV;
}

unless (defined $file{tess}) {
	
	if ($no_cgi) {
		
		pod2usage(2);
	}
	else {
		
		$session = "NA";
		$name{source} = ($query->param('source') || 'vergil.aeneid');
		$name{target} = ($query->param('target') || 'lucan.bellum_civile.part.1');
		html_no_table();
	}
	exit;
}

#
# read the data
#

# the benchmark data

my @bench = @{ retrieve($file{cache}) };

# the tesserae data

my %match_target = %{retrieve(catfile($file{tess}, "match.target"))};
my %match_source = %{retrieve(catfile($file{tess}, "match.source"))};
my %score        = %{retrieve(catfile($file{tess}, "match.score"))};
my %meta         = %{retrieve(catfile($file{tess}, "match.meta"))};
my %type;
my %auth;

$session = $meta{SESSION};

for (qw/target source/) {

	$name{$_} = $meta{uc($_)};
	$file{"token_$_"} = catfile($fs{data}, 'v3', Tesserae::lang($name{$_}), $name{$_}, $name{$_} . ".token");
	$file{"unit_$_"}  = catfile($fs{data}, 'v3', Tesserae::lang($name{$_}), $name{$_}, $name{$_} . ".phrase");
	$file{"freq_$_"}  = catfile($fs{data}, 'common', Tesserae::lang($meta{uc $_}) . '.stem.freq');
}

# now load the texts

my %unit;
my %token;



for (qw/target source/) {
 	
	@{$token{$_}}   = @{ retrieve($file{"token_$_"})};
	@{$unit{$_}}    = @{ retrieve($file{"unit_$_"}) };
	
}



# open target/source dictionaries for corpus-based stem frequencies.

# resolve the path to the stem dictionaries

my $target_dict_file = catfile($fs{data}, 'common', Tesserae::lang($meta{TARGET}) . '.stem.cache');

my $source_dict_file = catfile($fs{data}, 'common', Tesserae::lang($meta{SOURCE}) . '.stem.cache');	

# load the storable binaries
	
my %target_dictionary = %{retrieve($target_dict_file)};

my %source_dictionary = %{retrieve($source_dict_file)};	


# open frequency file



open (TARG, "$file{freq_target}") or die $!;
	
# build hash of feature, frequency in the text
my %freq_target;	
my %freq_source;

while (<TARG>) {

	if ($_ =~ /^#/) {
		next;
	}
	$_ =~ /^(\w+)\t(\d+)/;


	$freq_target{$1} = $2;
	
	
}

open (SOUR, "$file{freq_source}") or die $!;


# build hash of feature, frequency in the text

while (<SOUR>) {
	if ($_ =~ /^#/) {
		next;
	}
	
	$_ =~ /^(\w+)\t(\d+)/;
	$freq_source{$1} = $2;
	
	
}

	# Decide what the max number of matchwords is

my $max_match = 2;

for my $unit_id_target (keys %score) {

	for my $unit_id_source ( keys %{$score{$unit_id_target}} ) {
		
		my $current_match = scalar (keys %{$match_target{$unit_id_target}{$unit_id_source}});

		if ($current_match > $max_match) {
			
			$max_match = $current_match;
			
		}

		 $current_match = scalar (keys %{$match_source{$unit_id_target}{$unit_id_source}});

		if ($current_match > $max_match) {
			
			$max_match = $current_match;
			
		}
	}
}

#
# abbreviations of canonical citation refs
#

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

#
# compare 
#

my @count = (0)x7;
my @score = (0)x7;
my @total = (0)x7;
my @order = ();

# this records benchmark records not found by tesserae

my @missed;

# do the comparison

print STDERR "comparing\n" unless $quiet;
	
for my $i (0..$#bench) {
	
	my $auth   = $bench[$i]->get('auth');
	my $type   = $bench[$i]->get('type');
	my $unit_t = $bench[$i]->get('target_unit');
	my $unit_s = $bench[$i]->get('source_unit');
	
	if (defined $type) {

		$total[$type]++;
	}
	
	if (defined $auth) {
		
		$total[6]++;
	}
	
	if (defined $score{$unit_t}{$unit_s}) { 
		
		# tally the match for stats

		if (defined $type) {

			$count[$type]++;
			$score[$type] += $score{$unit_t}{$unit_s};
		
			# add the benchmark data to the tess parallel
		
			$type{$unit_t}{$unit_s} = $type;
		}

		if (defined $auth) {
			
			# tally commentator match
			
			$count[6]++;
			$score[6] += $score{$unit_t}{$unit_s};
			
			# add commentators to tess parallel
			
			$auth{$unit_t}{$unit_s} = $auth;
		}
		
		$bench[$i]->set('score', $score{$unit_t}{$unit_s});
				
		push @order, $i;
	}
	else {
	
		push @missed, $i;
	}
}	

unless ($quiet) {

	print STDERR "bench has " . scalar(@bench) . " records\n";
	print STDERR "order has " . scalar(@order) . " records\n";
	print STDERR "missed has " . scalar(@missed) . " records\n";
}

#
# load multi results
#

my @others;

my %multi = $process_multi ? %{load_multi()} : (); 

#
# output
#

binmode STDOUT, ":utf8";

if    ($export eq "summary") { summary()          }
elsif ($export eq "html")    { html_table()       }
elsif ($export =~ "^miss")   { print_missed("\t") }
else                         { print_delim("\t")  }


#
# subroutines
#


sub load_multi {

	#
	# first locate the multi-data directory
	#
	
	my $multi_dir;
	
	if ($session =~ /[0-9a-f]{8}/) {
	
		$multi_dir = catdir($fs{tmp}, "tesresults-$session", "multi");
	}
	else {
	
		$multi_dir = catdir($file{tess}, "multi");
	}
	
	#
	# get the textlist
	#
	
	@others = @{$meta{MTEXTLIST}};

	#
	# check every text
	#

	# this holds the data
	
	my %multi;

	# progress

	print STDERR "reading " . scalar(@others) . " files\n";
	
	my $pr = ProgressBar->new(scalar(@others));
	
	for my $other (@others) {
	
		$pr->advance;
	
		my $file_other = catfile($multi_dir, $other);
		
		$multi{$other} = retrieve($file_other);
	}
	
	return \%multi;
}

#
# output subroutines
#

sub summary {
	
	print "tesserae returned $meta{TOTAL} results\n";
	
	for (1..5) {
		
		my $rate =  $total[$_] > 0 ? sprintf("%.2f", $count[$_]/$total[$_]) : 'NA';
		my $score = $count[$_] > 0 ? sprintf("%.2f", $score[$_]/$count[$_]) : 'NA';
		
		print join("\t", $_, $count[$_], $total[$_], $rate, $score) . "\n";
	}
	
	my $rate =  $total[6] > 0 ? sprintf("%.2f", $count[6]/$total[6]) : 'NA';
	my $score = $count[6] > 0 ? sprintf("%.2f", $score[6]/$count[6]) : 'NA';
	
	print join("\t", "comm.", $count[6], $total[6], $rate, $score) . "\n";
}

sub html_table {
	
	my $mode = 'html';

	if ($sort eq 'score') {
		
		@order = sort { $bench[$a]->get('score')  <=> $bench[$b]->get('score') }
					sort { $bench[$a]->get('target_unit') <=> $bench[$b]->get('target_unit') }
					sort { $bench[$a]->get('source_unit') <=> $bench[$b]->get('source_unit') }	
					@order;
	}	
	elsif ($sort eq 'type') {
		
		@order = sort { $bench[$a]->get('type')   <=> $bench[$b]->get('type') }
					sort { $bench[$a]->get('score')  <=> $bench[$b]->get('score') }
					sort { $bench[$a]->get('target_unit') <=> $bench[$b]->get('target_unit') }
					sort { $bench[$a]->get('source_unit') <=> $bench[$b]->get('source_unit') }	
					@order;		
	}
	else {
		
		@order = sort { $bench[$a]->get('target_unit') <=> $bench[$b]->get('target_unit') }
					sort { $bench[$a]->get('source_unit') <=> $bench[$b]->get('source_unit') }	
					@order;
	}
	
	if ($rev) { @order = reverse @order }
	
	my $frame = `php -f $fs{html}/check_recall.php`;
	
	my $table_data ="";
	
	for my $i (@order) {
	
		my $unit_id_target = $bench[$i]->get('target_unit');
		my $unit_id_source = $bench[$i]->get('source_unit');
	
		# note marked words
	
		my %marked_target;
		my %marked_source;
		
		for (keys %{$match_target{$unit_id_target}{$unit_id_source}}) { 
		
			$marked_target{$_} = 1;
		}
		
		for (keys %{$match_source{$unit_id_target}{$unit_id_source}}) {
		
			$marked_source{$_} = 1;
		}

		# generate the phrases
		
		my $phrase_target;
		
		for (@{$unit{target}[$unit_id_target]{TOKEN_ID}}) {
		
			if (defined $marked_target{$_}) {
				$phrase_target .= "<span class=\"matched\">$token{target}[$_]{DISPLAY}</span>";
			}
			else {
				$phrase_target .= $token{target}[$_]{DISPLAY};
			}
		}
		
		my $phrase_source;
		
		for (@{$unit{source}[$unit_id_source]{TOKEN_ID}}) {
		
			if (defined $marked_source{$_}) {
				$phrase_source .= "<span class=\"matched\">$token{source}[$_]{DISPLAY}</span>";
			}
			else {
				$phrase_source .= $token{source}[$_]{DISPLAY};
			}
		}
		
		$table_data .= table_row($mode,
			$bench[$i]->get('target_loc'),
			$phrase_target,
			$bench[$i]->get('source_loc'),
			$phrase_source,
			$bench[$i]->get('type'),
			$bench[$i]->get('score'),
			(defined $bench[$i]->get('auth') ? join(",", @{$bench[$i]->get('auth')}) : "")
		);
	}

	my $recall_stats;
	
	for (1..5) {
		
		my $rate =  $total[$_] > 0 ? sprintf("%.2f", $count[$_]/$total[$_]) : 'NA';
		my $score = $count[$_] > 0 ? sprintf("%.2f", $score[$_]/$count[$_]) : 'NA';
		
		$recall_stats .= table_row($mode, 
			$_, 
			$count[$_], 
			$total[$_], 
			$rate, 
			$score
			);
	}
	
	my $rate =  $total[6] > 0 ? sprintf("%.2f", $count[6]/$total[6]) : 'NA';
	my $score = $count[6] > 0 ? sprintf("%.2f", $score[6]/$count[6]) : 'NA';
	
	$recall_stats .= table_row($mode, 
		"comm.", 
		$count[6], 
		$total[6], 
		$rate, 
		$score
		);
	
	$frame =~ s/<!--info-->/&info/e;
	
	$frame =~ s/<!--sort-->/&re_sort/e;

	$frame =~ s/<!--all-results-->/$meta{TOTAL}/;
	
	$frame =~ s/<!--recall-stats-->/$recall_stats/;
	
	$frame =~ s/<!--parallels-->/$table_data/;

	print $frame;
}

sub html_no_table {
				
	my $frame = `php -f $fs{html}/check_recall.php`;
	
	$frame =~ s/<!--info-->/&info/e; 

	$frame =~ s/<!--sort-->/<p><br>Click &quot;Compare texts&quot; to get started<\/p>/;
	
	print $frame;
}

sub info {
		
	my %sel_feature = (word => "", stem => "", syn=>"", syn_lem=>, '3gr' => "", trans1 => "", trans2 => "");
	my %sel_stbasis = (corpus => "", target => "", source => "", both => "");
	my %sel_dibasis = (span => "", span_target => "", span_source => "", 
                      freq => "", freq_target => "", freq_source => "");
	my %sel_scbasis = (word => "", stem => "", feature=>"");

	$sel_feature{($meta{FEATURE}||'stem')}   = 'selected="selected"';
	$sel_stbasis{($meta{STBASIS}||'corpus')} = 'selected="selected"';
	$sel_dibasis{($meta{DIBASIS}||'freq')}   = 'selected="selected"';

	my $scbasis = $meta{SCORE};
	if ($scbasis !~ /word|stem/ and $scbasis eq $meta{FEATURE}) { $scbasis = 'feature' }
	$sel_scbasis{$scbasis} = 'selected="selected"';

	my $cutoff = $meta{CUTOFF} || 0;
	my $stop   = defined $meta{STOP} ? $meta{STOP} : 10;
	my $dist   = defined $meta{DIST} ? $meta{DIST} : 999;
	
	my $cache = fileparse($file{cache}, qw/\.cache/);
	
	my @feature_choices;
	
	if (Tesserae::lang($name{target}) eq Tesserae::lang($name{source})) {
	
		@feature_choices = qw/word stem syn syn_lem 3gr/;
	}
	else {
	
		@feature_choices = qw/trans1 trans2/;
	}
	
	my $html_feature = join("\n", map { "<option value=\"$_\" $sel_feature{$_}>$_</option>" } @feature_choices);

	my $html = <<END;
	
	<form action="$url{cgi}/read_table.pl" method="post" ID="Form1">

		<h1>Benchmark Recall Test</h1>

		<table class="input">
			<tr>
				<th>Session:</th>
				<th>$session</th>
			</tr>
			<tr>
				<th>Source:</th>
				<th>$name{source}</th>
			</tr>
			<tr>
				<th>Target:</th>
				<th>$name{target}</th>
			</tr>
			<tr>
				<th>Unit:</th>
				<th>phrase</th>
			</tr>
			<tr>
				<th>Feature:</th>
				<td>
					<select name="feature">
						$html_feature
					</select>
				</td>
			</tr>
			<tr>
				<th>Number of stop words:</th>
				<td>
					<input type="text" name="stopwords" value="$stop">
				</td>
			</tr>
			<tr>
				<th>Stoplist basis:</th>
				<td>
					<select name="stbasis">
						<option value="corpus" $sel_stbasis{corpus}>corpus</option>
						<option value="target" $sel_stbasis{target}>target</option>
						<option value="source" $sel_stbasis{source}>source</option>
						<option value="both"   $sel_stbasis{both}>target + source</option>
					</select>
				</td>
			</tr>
			<tr>
				<th>Score basis:</th>
				<td>
					<select name="score">
						<option value="word"    $sel_scbasis{word}>word</option>
						<option value="stem"    $sel_scbasis{stem}>stem</option>
						<option value="feature" $sel_scbasis{feature}>feature</option>								
					</select>
				</td>
			</tr>	
			<tr>
				<th>Maximum distance:</th>
				<td>
					<input type="text" name="dist" maxlength="3" value="$dist">
				</td>
			</tr>
			<tr>
				<th>Distance metric:</th>
				<td>
					<select name="dibasis">
						<option value="span"        $sel_dibasis{span}>span</option>
						<option value="span_target" $sel_dibasis{span_target}>span-target</option>
						<option value="span_source" $sel_dibasis{span_source}>span-source</option>
						<option value="freq"        $sel_dibasis{freq}>frequency</option>
						<option value="freq_target" $sel_dibasis{freq_target}>freq-target</option>
						<option value="freq_source" $sel_dibasis{freq_source}>freq-source</option>
					</select>
				</td>
			</tr>
			<tr>
				<th>Drop scores below:</th>
				<td>
					<input type="text" name="cutoff" maxlen="3" value="$cutoff">
				</td>
			</tr>
		</table>
		
		<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
		
		<input type="hidden" name="source"       value="$name{source}" />
		<input type="hidden" name="target"       value="$name{target}" />
		<input type="hidden" name="recall_cache" value="$cache"        />
		<input type="hidden" name="unit"         value="phrase"        />
		<input type="hidden" name="frontend"     value="recall"        />
		
	</form>

END

	return $html;
	
}

sub re_sort {
	
	my @sel_rev     = ("", "");
	my %sel_sort    = (target => "", score => "", type=> "");
	
	$sel_rev[$rev]         = 'selected="selected"';
	$sel_sort{$sort}       = 'selected="selected"';
	
	my $cache = fileparse($file{cache}, qw/\.cache/);
	
	my $html = <<END;
	
	<form action="$url{cgi}/check-recall.pl" method="post" id="Form2">
		
		<table>
			<tr>
				<td>

			Sort results 

			<select name="rev">
				<option value="0" $sel_rev[0]>increasing</option>
				<option value="1" $sel_rev[1]>decreasing</option>
			</select>

			by

			<select name="sort">
				<option value="target" $sel_sort{target}>target locus</option>
				<option value="score"  $sel_sort{score}>tess score</option>
				<option value="type"   $sel_sort{type}>parallel type</option>
			</select>.
			
			</td>
			<td>
				<input type="hidden" name="session" value="$session" />
				<input type="hidden" name="cache"   value="$cache"   />
				<input type="submit" name="submit"  value="Change Display" />
			</td>
		</tr>
	</table>
	</form>
END

	return $html;
}


sub table_row {

	my ($mode, @cell) = @_;

	if ($mode eq "text") {
		
		for (0..$#cell) {
	
			my $w = $w[$_] || 10;
	
			$cell[$_] = sprintf("%-${w}s", $cell[$_]);
		}
	}
	
	my $row_open  = $mode eq "html" ? "\t<tr><td>" : "";
	my $row_close = $mode eq "html" ? "\t</td></tr>\n" : "\n";
	my $spacer    = $mode eq "html" ? "</td><td>" : " | ";
	
	my $row = $row_open . join($spacer, @cell) . $row_close;
	
	return $row;
}

sub print_delim {
	
	my $delim = shift;
	
	print STDERR "writing output\n";
	
	#
	# print header with settings info
	#
	
	my $stoplist = join(" ", @{$meta{STOPLIST}});
	my $filtertoggle = $meta{FILTER} ? 'on' : 'off';

	
	print "# Tesserae Multi-text results\n";
	print "#\n";
	print "# session   = $session\n";
	print "# source    = $meta{SOURCE}\n";
	print "# target    = $meta{TARGET}\n";
	print "# unit      = $meta{UNIT}\n";
	print "# feature   = $meta{FEATURE}\n";
	print "# stopsize  = $meta{STOP}\n";
	print "# stbasis   = $meta{STBASIS}\n";
	print "# stopwords = $stoplist\n";
	print "# max_dist  = $meta{DIST}\n";
	print "# dibasis   = $meta{DIBASIS}\n";
	print "# cutoff    = $meta{CUTOFF}\n";
	print "# filter    = $filtertoggle\n";

	if ($process_multi) {
	
		print "# multitext = " . join(" ", @{$meta{MTEXTLIST}}) . "\n";
		print "# m_cutoff  = $meta{MCUTOFF}\n";
	}
	
	my @header_begin = qw(
		"RESULT"
		"TARGET_PHRASE"
		"TARGET_BOOK"
		"TARGET_LINE"
		"TARGET_TEXT"
		"SOURCE_PHRASE"
		"SOURCE_BOOK"
		"SOURCE_LINE"
		"SOURCE_TEXT"
		"SHARED"
		"ORIGINAL_SCORE");
		
	my @header_end = qw(
		"TYPE"
		"AUTH");		
		
	my @header_middle;
	
	for my $tok (1..$max_match) {

		my $z = $tok - 1;
		
		$header_middle[$z] = "\"TARGET_TOKEN_$tok\"";
		
		$header_middle[$z+$max_match] = "\"TARGET_FREQUENCY_$tok\"";
		
		$header_middle[$z+$max_match+$max_match] = "\"SOURCE_TOKEN_$tok\"";
		
		$header_middle[$z+$max_match+$max_match+$max_match] = "\"SOURCE_FREQUENCY_$tok\"";
		
	}
	
	my @header = (@header_begin, @header_middle, @header_end);
		
	if ($process_multi) {
	
		push @header, qw/"OTHER_TEXTS" "OTHER_TOTAL"/;
		
		if ($process_multi > 1) {
		
			push @header, map { "\"$_\"" } @others;
		}
	}
	
	print join ($delim, @header) . "\n";



	my $pr = ProgressBar->new(scalar(keys %score));
		
	my $i = 0;

	for my $unit_id_target (keys %score) {
	
		$pr->advance();

		for my $unit_id_source ( keys %{$score{$unit_id_target}} ) {
				
			# a guide to which tokens are marked in each text
		
			my %marked_target;
			my %marked_source;
			
			# collect the keys
			
			my %seen_keys;
	
			for (keys %{$match_target{$unit_id_target}{$unit_id_source}}) { 
			
				$marked_target{$_} = 1;
			
				$seen_keys{join("-", sort keys %{$match_target{$unit_id_target}{$unit_id_source}{$_}})} = 1;
			}
			
			for (keys %{$match_source{$unit_id_target}{$unit_id_source}}) {
			
				$marked_source{$_} = 1;
	
				$seen_keys{join("-", sort keys %{$match_source{$unit_id_target}{$unit_id_source}{$_}})} = 1;
			}
		
			# format the list of all unique shared words
	
			my $keys = join("; ", keys %seen_keys);

			# get the score
		
			my $score = sprintf("%.3f", $score{$unit_id_target}{$unit_id_source});
			
			# At this point, it's possible to generate a list of info instead of a single score. Start with token IDs and freq values.
			# Start with an array of token IDs.
			
			my @target_tokens = keys %marked_target;
			
			my @source_tokens = keys %marked_source;

			# build the array of frequencies

			my @target_freqs;
			my @source_freqs;
						
			# the following assumes that the feature is 'word' and the frequencies should be drawn from the texts.
			
			for my $z (0..$#target_tokens) {
				
				#access the .token data file for this work, which is an array whose addresses are equivalent to token ids and whose values are hashes 
				
				
				if (${${$token{target}}[$target_tokens[$z]]}{FORM}) {
			
					$target_freqs[$z] = stem_frequency(${${$token{target}}[$target_tokens[$z]]}{FORM}, 'target');
				
				}
				else {
					
					$target_freqs[$z] = 'NA';
					
				}
			}
			
			for my $z (0..$#source_tokens) {
				
				if (${${$token{source}}[$source_tokens[$z]]}{FORM}) {
			
					$source_freqs[$z] = stem_frequency(${${$token{source}}[$source_tokens[$z]]}{FORM}, 'source');
				
				}
				else {
					
					$source_freqs[$z] = 'NA';
					
				}			
			}
			
			# the target and source frequencies and token IDs must be joined in an array whose length is great enough to accept the largest number of possible matchwords.
			
			if (scalar(@target_tokens) < $max_match) {
				
				my $start = $#target_tokens + 1;
				
				for my $z ($start..($max_match - 1)) {
				
					$target_tokens[$z] = 'NA';

					$target_freqs[$z] = 'NA';

				
				}
				
			}
			
			
			if (scalar(@source_tokens) < $max_match) {
				
				my $start = $#source_tokens + 1;
				
				for my $z ($start..($max_match - 1)) {
				
					$source_tokens[$z] = 'NA';

					$source_freqs[$z] = 'NA';

				
				}
				
			}
			my @score = ($score, @target_tokens, @target_freqs, @source_tokens, @source_freqs);

			# get benchmark data

			my $type = $type{$unit_id_target}{$unit_id_source} || "";
			
			my $auth = "";
			
			if (defined $auth{$unit_id_target}{$unit_id_source}) {
			
				$auth = '"' . join(",", @{$auth{$unit_id_target}{$unit_id_source}}) . '"';
			}
			
			#
			# now prepare the csv record for this match
			#

			my @row;
		
			# result serial number
		
			push @row, ++$i;
		
			# target phrase id
			
			push @row, $unit_id_target;
		
			# target locus
			
			my $loc_target = $unit{target}[$unit_id_target]{LOCUS};
		
			push @row, (split('\.', $loc_target));
		
			# target phrase
		
			my $phrase = "";
				
			for my $token_id_target (@{$unit{target}[$unit_id_target]{TOKEN_ID}}) {
		
				if ($marked_target{$token_id_target}) { $phrase .= "**" }
		
				$phrase .= $token{target}[$token_id_target]{DISPLAY};

				if ($marked_target{$token_id_target}) { $phrase .= "**" }
			}
		
			push @row, "\"$phrase\"";
					
			# source phrase id
			
			push @row, $unit_id_source;
					
			# source locus
			
			my $loc_source = $unit{source}[$unit_id_source]{LOCUS};
						
			push @row, (split('\.', $loc_source));
			
			# source phrase
			
			$phrase = "";
			
			for my $token_id_source (@{$unit{source}[$unit_id_source]{TOKEN_ID}}) {
			
				if ($marked_source{$token_id_source}) { $phrase .= "**" }
			
				$phrase .= $token{source}[$token_id_source]{DISPLAY};
				
				if ($marked_source{$token_id_source}) { $phrase .= "**" }
			}
					
			push @row, "\"$phrase\"";
		
			# keywords
			
			push @row, "\"$keys\"";

			# score

			push @row, @score;
			
			# At this point, it's possible to interrupt the program with a list of info instead of a single score.
			
	
			# benchmark data
			
			push @row, ($type, $auth);
		
			# multi-text search
			
			if ($process_multi) {
		
				my $other_texts = 0;
				my $other_total = 0;
			
				my %m;
				@m{@others} = ("") x scalar(@others);
			
				for my $other (@others) {
			
					if (defined $multi{$other}{$unit_id_target}{$unit_id_source}) {
					
						my @loci;
						
						for (sort {$a <=> $b} keys %{$multi{$other}{$unit_id_target}{$unit_id_source}}) {
							
							my $locus = $multi{$other}{$unit_id_target}{$unit_id_source}{$_}{LOCUS};
							my $score = $multi{$other}{$unit_id_target}{$unit_id_source}{$_}{SCORE};
							$score = sprintf("%.0f", $score);
							
							push @loci, "$locus ($score)";
						}
						
						$m{$other} = '"' . join("; ", @{loci}) . '"';
	
						$other_texts++;
											
						$other_total += scalar(@loci);
					}
				}
			
				push @row, ($other_texts, $other_total);
			
				push @row, @m{@others} if $process_multi > 1;
			}
		
			# print row
		
			print join($delim, @row) . "\n";
		}
	}
}


sub print_missed {
	
	my $delim = shift;
		
	print STDERR "writing output\n";
	
	#
	# print header with settings info
	#
	
	my $stoplist = join(" ", @{$meta{STOPLIST}});
	my $filtertoggle = $meta{FILTER} ? 'on' : 'off';

	
	print "# Tesserae missed results\n";
	print "#\n";
	print "# session   = $session\n";
	print "# source    = $meta{SOURCE}\n";
	print "# target    = $meta{TARGET}\n";
	print "# unit      = $meta{UNIT}\n";
	print "# feature   = $meta{FEATURE}\n";
	print "# stopsize  = $meta{STOP}\n";
	print "# stbasis   = $meta{STBASIS}\n";
	print "# stopwords = $stoplist\n";
	print "# max_dist  = $meta{DIST}\n";
	print "# dibasis   = $meta{DIBASIS}\n";
	print "# cutoff    = $meta{CUTOFF}\n";
	print "# filter    = $filtertoggle\n";
	
	my @header = qw(
		"RESULT"
		"TARGET_BOOK"
		"TARGET_LINE"
		"TARGET_TEXT"
		"SOURCE_BOOK"
		"SOURCE_LINE"
		"SOURCE_TEXT"
		"NSHARED"
		"SHARED"
		"TYPE"
		"AUTH");
			
	print join ($delim, @header) . "\n";

	my $pr = ProgressBar->new(scalar(@missed));

	for my $i (0..$#missed) {
	
		$pr->advance();

		my $rec = $bench[$missed[$i]];

		my $unit_id_target = $rec->get('unit_t');
		my $unit_id_source = $rec->get('unit_s');
		my $type = $rec->get('type');
		my $auth = defined $rec->get('auth') ? join(",", @{$rec->get('auth')}) : "";
			
		# do a tess search on these two phrases

		my %mini_results = %{minitess($unit_id_target, $unit_id_source, $meta{STOPLIST})};
		
		# get the marked words if any
		
		my %marked_target = %{$mini_results{marked_target}};
		my %marked_source = %{$mini_results{marked_source}};
		
		# format the list of all unique shared words
		
		my $nkeys = scalar(@{$mini_results{seen_keys}});
	
		my $keys = join("; ", @{$mini_results{seen_keys}});

		#
		# now prepare the csv record for this match
		#

		my @row;
	
		# result serial number
	
		push @row, ++$i;
	
		# target locus
		
		my $loc_target = $unit{target}[$unit_id_target]{LOCUS};
	
		push @row, (split('\.', $loc_target));
	
		# target phrase
		
		my $phrase = "";
			
		for my $token_id_target (@{$unit{target}[$unit_id_target]{TOKEN_ID}}) {
	
			if ($marked_target{$token_id_target}) { $phrase .= "**" }
	
			$phrase .= $token{target}[$token_id_target]{DISPLAY};

			if ($marked_target{$token_id_target}) { $phrase .= "**" }
		}
		
		push @row, "\"$phrase\"";
				
		# source locus
		
		my $loc_source = $unit{source}[$unit_id_source]{LOCUS};
					
		push @row, (split('\.', $loc_source));
		
		# source phrase
		
		$phrase = "";
		
		for my $token_id_source (@{$unit{source}[$unit_id_source]{TOKEN_ID}}) {
		
			if ($marked_source{$token_id_source}) { $phrase .= "**" }
		
			$phrase .= $token{source}[$token_id_source]{DISPLAY};
			
			if ($marked_source{$token_id_source}) { $phrase .= "**" }
		}
				
		push @row, "\"$phrase\"";
	
		# keywords
		
		push @row, ($nkeys, "\"$keys\"");

		# benchmark data
		
		push @row, ($type, $auth);
		
		# print row
	
		print join($delim, @row) . "\n";
	}
}

# perform the equivalent of a tesserae search on just two phrases

sub minitess {

	my %unit_id;
	my $stoplistref;
	
	my %results;

	($unit_id{target}, $unit_id{source}, $stoplistref) = @_;
	
	my @stoplist = @$stoplistref;
	
	#
	# for each phrase, create an index of word tokens by their stems
	#
	
	my %index;
		
	for my $text (qw/target source/) {
		
		my $lang = Tesserae::lang($name{$text});
	
		for my $token_id (@{$unit{$text}[$unit_id{$text}]{TOKEN_ID}}) {

			next unless $token{$text}[$token_id]{TYPE} eq "WORD";
		
			my $word = $token{$text}[$token_id]{FORM};

			for my $feat (@{Tesserae::feat($lang, $meta{FEATURE}, $word)}) {
			
				push @{$index{$feat}{$text}}, $token_id;
			}
		}
	}
	
	for (@stoplist) {
	
		delete $index{$_} if defined $index{$_};
	}
	
	#
	# check the index for stems that occur in both phrases
	#
	
	my %marked;
	my %seen_keys;
	
	for my $feat (keys %index) {
	
		next unless defined ($index{$feat}{target} and $index{$feat}{source});
		
		# mark all tokens that share a common stem
		
		for my $text (qw/target source/) {
			
			my $lang = Tesserae::lang($name{$text});
		
			for my $token_id (@{$index{$feat}{$text}}) {
			
				$marked{$text}{$token_id} = 1;
				
				my @feats = @{Tesserae::feat($lang, $meta{FEATURE}, $token{$text}[$token_id]{FORM})};
				
				$seen_keys{join("-", sort @feats)} = 1;
			}
		}
	}
	
	$results{marked_target} = $marked{target}   || {};
	$results{marked_source} = $marked{source}   || {};
	$results{seen_keys}     = [keys %seen_keys];
	
	return \%results;
}


# take an inflected form, and return the average corpus-wide frequency value of the associated stems
sub stem_frequency {
	
	my ($form, $text) = @_;
	
	# this subroutine is agnostic of language but must be fed the appropriate text (target or source)
	
	my $average;
		
	if ($text eq 'target') {
	
		# load all possible stems
	
		my @stems;

		if ($target_dictionary{$form}) {
		
		 	@stems = @{$target_dictionary{$form}};
		 	
		}
		else {
		
			$stems[0] = $form;
			
		}
	
		# retrieve corpus-wide frequency values for each stem
	
		my $freq_values;
	
		for (0..$#stems) {
		
			$freq_values += $freq_target{$stems[$_]};
		
		}
	
		# average the frequencies
	
		$average = $freq_values / (scalar @stems);
		
	}
	else {
	
		# load all possible stems
	
		my @stems;

		if ($source_dictionary{$form}) {
		
		 	@stems = @{$source_dictionary{$form}};
		 	
		}
		else {
		
			$stems[0] = $form;
			
		}
	
		# retrieve corpus-wide frequency values for each stem
	
		my $freq_values;
	
		for (0..$#stems) {
		
			$freq_values += $freq_source{$stems[$_]};
		
		}
	
		# average the frequencies
	
		$average = $freq_values / (scalar @stems);
		
	}
	
	
	return $average;

}

