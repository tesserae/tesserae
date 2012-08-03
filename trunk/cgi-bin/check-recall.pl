#! /opt/local/bin/perl

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

use lib '/Users/chris/Sites/tesserae/perl'; # PERL_PATH
use TessSystemVars;
use EasyProgressBar;

my $usage = "usage: perl check-recall [--cache CACHE] TESRESULTS\n";

my $table = 0;
my $session;
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
	"table"          => \$table
	);

#
# CGI options
#

unless ($no_cgi) {
	
	print header();
	
	$session = $query->param('session');
	$table = 1;
}

#
# the file to read
#

if (defined $session) {

	$file{tess} = catfile($fs_tmp, "tesresults-" . $session . ".bin");
}
else {
	
	$file{tess}  = shift @ARGV;
}

unless (defined $file{tess}) {
	
	if ($no_cgi) {
		print STDERR $usage;
	}
	else {
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
		
	@order = sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
				sort { $bench[$a]{AEN_PHRASEID} <=> $bench[$b]{AEN_PHRASEID} }
	
				(@order);
	
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
	
	my $stoplist = join(", ", @{$tess{META}{STOPLIST}});

	$frame =~ s/<!--session_id-->/$tess{META}{SESSION}/;
	$frame =~ s/<!--unit-->/$tess{META}{UNIT}/s;
	$frame =~ s/<!--feature-->/$tess{META}{FEATURE}/;
	$frame =~ s/<!--stoplist-->/$stoplist/;
	$frame =~ s/<!--stbasis-->/$tess{META}{STBASIS}/;
	$frame =~ s/<!--dist-->/$tess{META}{DIST}/;
	$frame =~ s/<!--dibasis-->/$tess{META}{DIBASIS}/;
	$frame =~ s/<!--comment-->/$tess{META}{COMMENT}/;
	$frame =~ s/<!--all-results-->/$tess{META}{TOTAL}/;
	
	$frame =~ s/<!--recall-stats-->/$recall_stats/;
	
	$frame =~ s/<!--parallels-->/$table_data/;

	print $frame;
}

sub html_no_table {
				
	my $frame = `php -f $fs_html/check_recall.php`;
	
	my $parallels = "<tr><td colspan=\"7\">No data</td></tr>";
	my $recall_stats = "<tr><td colspan=\"5\">Click &quot;Search&quot; to get started</td></tr>";

	$frame =~ s/<!--session_id-->/NA/;
	$frame =~ s/<!--unit-->/NA/s;
	$frame =~ s/<!--feature-->/NA/;
	$frame =~ s/<!--stoplist-->/NA/;
	$frame =~ s/<!--stbasis-->/NA/;
	$frame =~ s/<!--dist-->/NA/;
	$frame =~ s/<!--dibasis-->/NA/;
	$frame =~ s/<!--comment-->/NA/;
	$frame =~ s/<!--all-results-->/NA/;
	
	$frame =~ s/<!--recall-stats-->/$recall_stats/;
	
	$frame =~ s/<!--parallels-->/$parallels/;

	print $frame;
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
