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
use Getopt::Long;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use EasyProgressBar;

my $usage = "usage: perl check-recall [--cache CACHE] TESRESULTS\n";

my $session;

my $feature = 'stem';
my $stopwords = 10;
my $stoplist_basis = "corpus";
my $max_dist = 999;
my $distance_metric = "span";
my $cutoff = 0;
my $interest = 0.0008;

my $table = 0;
my $sort = 'score';
my $rev = 1;

my @w = (7);
my $quiet = 1;

my %file = (
	
	lucan_token         => "$fs_data/v3/la/lucan.pharsalia.part.1/lucan.pharsalia.part.1.token",
	lucan_phrase        => "$fs_data/v3/la/lucan.pharsalia.part.1/lucan.pharsalia.part.1.phrase",
	
	vergil_token        => "$fs_data/v3/la/vergil.aeneid/vergil.aeneid.token",
	vergil_phrase       => "$fs_data/v3/la/vergil.aeneid/vergil.aeneid.phrase",
	
	cache     => "$fs_data/bench/rec.cache"
);


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
	"interesting"    => \$interest,
	"reverse"        => \$rev,
	"table"          => \$table
	);

#
# CGI options
#

unless ($no_cgi) {
	
	print header();
	
	$session    = $query->param('session');
	$sort       = $query->param('sort')    || $sort;
	$rev        = $query->param('rev')     || $rev;
	$table = 1;
}

#
# the file to read
#

if (defined $session) {

	$file{tess} = catfile($fs_tmp, "tesresults-" . $session . ".bin");
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

my @bench = @{ retrieve($file{cache}) };

my %tess = %{ retrieve($file{tess}) };

my %phrase;
my %token;

for my $text ('lucan', 'vergil') {
	
	@{$token{$text}}   = @{ retrieve($file{$text. "_token"})   };
	@{$phrase{$text}}  = @{ retrieve($file{$text. "_phrase"}) };
}

#
# compare 
#

my @count = (0)x7;
my @score = (0)x7;
my @total = (0)x7;
my @order = ();

# do the comparison

print STDERR "comparing\n" unless $quiet;
	
for my $i (0..$#bench) {
	
	my %rec = %{$bench[$i]};
	
	$total[$rec{SCORE}]++;

	if (defined $rec{AUTH}) {
		
		$total[6]++;
	}
	
	if (defined $tess{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}}) { 
		
		$count[$rec{SCORE}]++;
		$score[$rec{SCORE}] += $tess{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}}{SCORE};

		if (defined $rec{AUTH}) {
			
			$count[6]++;
			$score[6] += $tess{$rec{BC_PHRASEID}}{$rec{AEN_PHRASEID}}{SCORE};

		}
				
		push @order, $i;
	}
}	



# print results

if    ($table)		{ html_table("html")  }

else              { text_detail("text") }



#
# subroutines
#

sub compare {

	my ($benchref, $tessref) = @_;
	
	my @bench = @$benchref;
	my %tess  = %$tessref;
		
	my %in_tess;
	my $exists = 0;
	
	print STDERR "comparing\n" unless $quiet;
	
	# my $pr = ProgressBar->new(scalar(@bench));
		
	for (@bench) {
	
		# $pr->advance();
		
		if (defined $tess{$$_{BC_PHRASEID}}{$$_{AEN_PHRASEID}}) {
			
			$exists++;
		}
	}
	
	return $exists;
}


#
# output subroutines
#

sub text_detail {
	
	print "tesserae returned $tess{META}{TOTAL} results\n";
	
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
	
	my $mode = shift;

	if ($sort eq 'score') {
		
		@order = sort { $tess{$bench[$a]{BC_PHRASEID}}{$bench[$a]{AEN_PHRASEID}}{SCORE} <=> $tess{$bench[$b]{BC_PHRASEID}}{$bench[$b]{AEN_PHRASEID}}{SCORE} }
					sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
					sort { $bench[$a]{AEN_PHRASEID} <=> $bench[$b]{AEN_PHRASEID} }	
				(@order);		
	}	
	elsif ($sort eq 'type') {
		
		@order = sort { $bench[$a]{SCORE}  <=> $bench[$b]{SCORE} }
					sort { $tess{$bench[$a]{BC_PHRASEID}}{$bench[$a]{AEN_PHRASEID}}{SCORE} <=> $tess{$bench[$b]{BC_PHRASEID}}{$bench[$b]{AEN_PHRASEID}}{SCORE} }
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
		
		my $phrase_lucan;
		my %marked_lucan = %{$tess{$bench[$i]{BC_PHRASEID}}{$bench[$i]{AEN_PHRASEID}}{MARKED_TARGET}};
		
		for (@{$phrase{lucan}[$bench[$i]{BC_PHRASEID}]{TOKEN_ID}}) {
		
			if (defined $marked_lucan{$_}) {
				$phrase_lucan .= "<span class=\"matched\">$token{lucan}[$_]{DISPLAY}</span>";
			}
			else {
				$phrase_lucan .= $token{lucan}[$_]{DISPLAY};
			}
		}
		
		my $phrase_vergil;
		my %marked_vergil = %{$tess{$bench[$i]{BC_PHRASEID}}{$bench[$i]{AEN_PHRASEID}}{MARKED_SOURCE}};
		
		for (@{$phrase{vergil}[$bench[$i]{AEN_PHRASEID}]{TOKEN_ID}}) {
		
			if (defined $marked_vergil{$_}) {
				$phrase_vergil .= "<span class=\"matched\">$token{vergil}[$_]{DISPLAY}</span>";
			}
			else {
				$phrase_vergil .= $token{vergil}[$_]{DISPLAY};
			}
		}
		
		$table_data .= table_row($mode,
				   $bench[$i]{BC_BOOK}  . '.' . $bench[$i]{BC_LINE},
				   $phrase_lucan,
				   $bench[$i]{AEN_BOOK} . '.' . $bench[$i]{AEN_LINE},
				   $phrase_vergil,
				   $bench[$i]{SCORE},
				   $tess{$bench[$i]{BC_PHRASEID}}{$bench[$i]{AEN_PHRASEID}}{SCORE},
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
	
	$session = $tess{META}{SESSION};
	$feature = $tess{META}{FEATURE};
	$stopwords = scalar(@{$tess{META}{STOPLIST}});
	$stoplist_basis = $tess{META}{STBASIS};
	$max_dist = $tess{META}{DIST};
	$distance_metric = $tess{META}{DIBASIS};
	$cutoff = $tess{META}{CUTOFF};

	$frame =~ s/<!--info-->/&info/e;
	
	$frame =~ s/<!--sort-->/&re_sort/e;

	$frame =~ s/<!--all-results-->/$tess{META}{TOTAL}/;
	
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
		
	my %sel_feature = (word => "", stem => "", syn=>"");
	my %sel_stbasis = (corpus => "", target => "", source => "", both => "");
	my %sel_dibasis = (span => "", span_target => "", span_source => "", 
                      freq => "", freq_target => "", freq_source => "");

	$sel_feature{$feature}         = 'selected="selected"';
	$sel_stbasis{$stoplist_basis}  = 'selected="selected"';
	$sel_dibasis{$distance_metric} = 'selected="selected"';

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
					</select>
				</td>
			</tr>
			<tr>
				<td><span class="h2">Number of stop words:</span></td>
				<td>
					<input type="text" name="stopwords" value="$stopwords">
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
					<input type="text" name="dist" maxlength="3" value="$max_dist">
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
					<input type="text" name="cutoff" value="$cutoff">
				</td>
			</tr>
			<tr>
				<td><span class="h2">Minimum frequency for interesting words:</span></td>
				<td>
					<input type="text" name="interest" value="$interest">
				</td>
			</tr>						
		</table>
		
		<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
		
		<input type="hidden" name="source" value="vergil.aeneid"/>
		<input type="hidden" name="target" value="lucan.pharsalia.part.1"/>
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
