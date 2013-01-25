#! /opt/local/bin/perl5.12

# check-recall.pl
#
# this checks Tesserae output against a benchmark set
# previously saved as a binary using build-rec.pl
#
# its purpose is to tell you what portion of the benchmark
# allusions are present in your tesserae results.


use strict;
use warnings;

use CGI qw(:standard);

use Storable;
use File::Spec::Functions;
use File::Basename;
use Getopt::Long;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use EasyProgressBar;

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

my %name = ( source => 'vergil.aeneid', target => 'lucan.bellum_civile.part.1');

my %file;

$file{cache} = catfile($fs_data, 'bench', 'rec.cache');

for (qw/target source/) {

	$file{"token_$_"} = catfile($fs_data, 'v3', 'la', $name{$_}, $name{$_} . ".token");
	$file{"unit_$_"}  = catfile($fs_data, 'v3', 'la', $name{$_}, $name{$_} . ".phrase");
}

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# commandline options
#

GetOptions(
	"cache=s"        => \$file{cache},
	"session=s"      => \$session,
	"sort=s"         => \$sort,
	"reverse"        => \$rev,
	"multi=i"        => \$process_multi,
	"export=s"       => \$export
	);

#
# CGI options
#

unless ($no_cgi) {
		
	# form data
		
	$session    = $query->param('session');
	$sort       = $query->param('sort')    || $sort;
	$export     = $query->param('export')  || 'html';
	$rev        = $query->param('rev') if defined $query->param('rev');
	
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

	$file{tess} = catfile($fs_tmp, "tesresults-" . $session);
}
else {
	
	$file{tess} = shift @ARGV;
}

unless (defined $file{tess}) {
	
	if ($no_cgi) {
		print STDERR $usage;
	}
	else {
		$session = "NA";
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


# now load the texts

my %unit;
my %token;

for (qw/target source/) {
 	
	@{$token{$_}}   = @{ retrieve($file{"token_$_"})};
	@{$unit{$_}}    = @{ retrieve($file{"unit_$_"}) };
}

#
# abbreviations of canonical citation refs
#

my $file_abbr = catfile($fs_data, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

#
# dictionaries - loaded only if necessary
#

my $file_stem = catfile($fs_data, 'common', 'la.stem.cache');
my $file_syn  = catfile($fs_data, 'common', 'la.syn.cache');

my %stem;
my %syn;

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
	
	my %rec = %{$bench[$i]};
	
	$total[$rec{SCORE}]++;

	if (defined $rec{AUTH}) {
		
		$total[6]++;
	}
	
	if (defined $score{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}}) { 
		
		# tally the match for stats
		
		$count[$rec{SCORE}]++;
		$score[$rec{SCORE}] += $score{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}};
		
		# add the benchmark data to the tess parallel
		
		$type{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}} = $rec{SCORE};

		if (defined $rec{AUTH}) {
			
			# tally commentator match
			
			$count[6]++;
			$score[6] += $score{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}};
			
			# add commentators to tess parallel
			
			$auth{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}} = $rec{AUTH};
			
		}
				
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
	
		$multi_dir = catdir($fs_tmp, "tesresults-$session", "multi");
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
		
		@order = sort { $score{$bench[$a]{BC_PHRASEID}}{$bench[$a]{AEN_PHRASEID}} <=> $score{$bench[$b]{BC_PHRASEID}}{$bench[$b]{AEN_PHRASEID}} }
					sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
					sort { $bench[$a]{AEN_PHRASEID} <=> $bench[$b]{AEN_PHRASEID} }	
				(@order);		
	}	
	elsif ($sort eq 'type') {
		
		@order = sort { $bench[$a]{SCORE}  <=> $bench[$b]{SCORE} }
					sort { $score{$bench[$a]{BC_PHRASEID}}{$bench[$a]{AEN_PHRASEID}} <=> $score{$bench[$b]{BC_PHRASEID}}{$bench[$b]{AEN_PHRASEID}} }
					sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
				(@order);		
	}
	else {
		
		@order = sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
					sort { $bench[$a]{AEN_PHRASEID} <=> $bench[$b]{AEN_PHRASEID} }	
				(@order);
	}
	
	if ($rev) { @order = reverse @order }
	
	my $frame = `php -f $fs_html/check_recall.php`;
	
	my $table_data;
	
	for my $i (@order) {
	
		my $unit_id_target = $bench[$i]{BC_PHRASEID};
		my $unit_id_source = $bench[$i]{AEN_PHRASEID};
	
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
				   $bench[$i]{BC_BOOK}  . '.' . $bench[$i]{BC_LINE},
				   $phrase_target,
				   $bench[$i]{AEN_BOOK} . '.' . $bench[$i]{AEN_LINE},
				   $phrase_source,
				   $bench[$i]{SCORE},
				   $score{$unit_id_target}{$unit_id_source},
				   (defined $bench[$i]{AUTH} ? join(",", @{$bench[$i]{AUTH}}) : "")
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
				
	my $frame = `php -f $fs_html/check_recall.php`;
	
	$frame =~ s/<!--info-->/&info/e; 

	$frame =~ s/<!--sort-->/<p><br>Click &quot;Compare texts&quot; to get started<\/p>/;
	
	print $frame;
}

sub info {
		
	my %sel_feature = (word => "", stem => "", syn=>"", '3gr' => "");
	my %sel_stbasis = (corpus => "", target => "", source => "", both => "");
	my %sel_dibasis = (span => "", span_target => "", span_source => "", 
                      freq => "", freq_target => "", freq_source => "");
    my @sel_filter = ("", "");

	$sel_feature{($meta{FEATURE}||'stem')}   = 'selected="selected"';
	$sel_stbasis{($meta{STBASIS}||'corpus')} = 'selected="selected"';
	$sel_dibasis{($meta{DIBASIS}||'freq')}   = 'selected="selected"';
	$sel_filter[$meta{FILTER}]   = 'checked="checked"';

	my $cutoff = $meta{CUTOFF} || 0;
	my $stop   = defined $meta{STOP} ? $meta{STOP} : 10;
	my $dist   = defined $meta{DIST} ? $meta{DIST} : 999;

	my $html = <<END;
	
	<form action="$url_cgi/read_table.pl" method="post" ID="Form1">

		<h1>Lucan-Vergil Recall Test</h1>

		<table class="input">
			<tr>
				<td><span class="h2">Session:</span></td>
				<td>$session</td>
			</tr>
			<tr>
				<td><span class="h2">Source:</span></td>
				<td>Vergil - Aeneid</td>
			</tr>
			<tr>
				<td><span class="h2">Target:</span></td>
				<td>Lucan - Pharsalia - Book 1</td>
			</tr>
			<tr>
				<td><span class="h2">Unit:</span></td>
				<td>Phrase</td>
			</tr>
			<tr>
				<td><span class="h2">Feature:</span></td>
				<td>
					<select name="feature">
						<option value="word" $sel_feature{word}>exact form only</option>
						<option value="stem" $sel_feature{stem}>lemma</option>
						<option value="syn"  $sel_feature{syn}>lemma + synonyms</option>
						<option value="3gr"  $sel_feature{'3gr'}>character 3-grams</option>
					</select>
				</td>
			</tr>
			<tr>
				<td><span class="h2">Number of stop words:</span></td>
				<td>
					<input type="text" name="stopwords" value="$stop">
				</td>
			</tr>
			<tr>
				<td><span class="h2">Stoplist basis:</span></td>
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
				<td><span class="h2">Maximum distance:</span></td>
				<td>
					<input type="text" name="dist" maxlength="3" value="$dist">
				</td>
			</tr>
			<tr>
				<td><span class="h2">Distance metric:</span></td>
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
				<td><span class="h2">Drop scores below:</span></td>
				<td>
					<input type="text" name="cutoff" maxlen="3" value="$cutoff">
				</td>
			</tr>
			<tr>
				<td><span class="h2">Scoring Team filter:</span></td>
				<td>
					<input type="radio" name="filter" value="1" $sel_filter[1]> ON
					<input type="radio" name="filter" value="0" $sel_filter[0]> OFF
				</td>
			</tr>
		</table>
		
		<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
		
		<input type="hidden" name="source" value="vergil.aeneid"/>
		<input type="hidden" name="target" value="lucan.bellum_civile.part.1"/>
		<input type="hidden" name="unit" value="phrase"/>
		<input type="hidden" name="frontend" value="recall"/>
		
	</form>

END

	return $html;
	
}

sub re_sort {
	
	my @sel_rev     = ("", "");
	my %sel_sort    = (target => "", score => "", type=> "");
	
	$sel_rev[$rev]         = 'selected="selected"';
	$sel_sort{$sort}       = 'selected="selected"';
	
	my $html = <<END;
	
	<form action="$url_cgi/check-recall.pl" method="post" id="Form2">
		
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
				<input type="submit" name="submit" value="Change Display" />
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
	
	my @header = qw(
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
		"SCORE"
		"TYPE"
		"AUTH");
		
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

			push @row, $score;
	
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
							$score = sprintf("%i", $score);
							
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
	
	#
	# for this we need the dictionaries
	#
	
	print STDERR "loading stem dictionary\n";
	
	%stem = %{retrieve($file_stem)};
	
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

		my %rec = %{$bench[$missed[$i]]};

		my $unit_id_target = $rec{BC_PHRASEID};
		my $unit_id_source = $rec{AEN_PHRASEID};
		my $type = $rec{SCORE};
		my $auth = defined $rec{AUTH} ? join(",", @{$rec{AUTH}}) : "";
			
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
	
		for my $token_id (@{$unit{$text}[$unit_id{$text}]{TOKEN_ID}}) {

			next unless $token{$text}[$token_id]{TYPE} eq "WORD";
		
			my $word = $token{$text}[$token_id]{FORM};

			for my $stem (@{stems($word)}) {
			
				push @{$index{$stem}{$text}}, $token_id;
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
	
	for my $stem (keys %index) {
	
		next unless defined ($index{$stem}{target} and $index{$stem}{source});
		
		# mark all tokens that share a common stem
		
		for my $text (qw/target source/) {
		
			for my $token_id (@{$index{$stem}{$text}}) {
			
				$marked{$text}{$token_id} = 1;
				
				my @stems = @{stems($token{$text}[$token_id]{FORM})};
				
				$seen_keys{join("-", sort @stems)} = 1;
			}
		}
	}
	
	$results{marked_target} = $marked{target}   || {};
	$results{marked_source} = $marked{source}   || {};
	$results{seen_keys}     = [keys %seen_keys];
	
	return \%results;
}

sub stems {

	my $form = shift;
	
	my @stems;
	
	if ($use_lingua_stem) {
	
		@stems = @{$stemmer->stem($form)};
	}
	elsif (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}

sub syns {

	my $form = shift;
	
	my %syns;
	
	for my $stem (@{stems($form)}) {
	
		if (defined $syn{$stem}) {
		
			for (@{$syn{$stem}}) {
			
				$syns{$_} = 1;
			}
		}
	}
	
	return [keys %syns];
}
