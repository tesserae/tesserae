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

use Storable;
use Getopt::Long;

use lib '/Users/chris/tesserae/perl';
use EasyProgressBar;

my $usage = "usage: perl check-recall [--cache CACHE] TESRESULTS\n";

#
# commandline options
#

my $file_cache = "data/rec.cache";
my $table  = 0;
my $detail = 0;

GetOptions("cache=s" => \$file_cache, "verbose|detail" => \$detail, "table" => \$table);

#
# the file to read
#

my $file_tess  = shift @ARGV;

unless (defined $file_tess) {
	
	print STDERR $usage;
	exit;
}

my $quiet = 1;

#
# read the data
#

my @bench = @{ retrieve($file_cache) };

my %tess = %{ retrieve($file_tess) };

#
# compare 
#

print "tesserae returned $tess{META}{TOTAL} results\n";

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

if    ($table)		{ print_html_table()  }

elsif ($detail)     { print_detail() }

else {

	my $rate =  $total[6] > 0 ? sprintf("%.2f", $count[6]/$total[6]) : 'NA';
	
	print join("\t", "comm.", $count[6], $total[6], $rate) . "\n";	
}



#
# subroutines
#

sub readTess {

	my $file = shift;
	
	my @res;
	
	open(FH, "<:utf8", $file) || die "can't read $file: $!";
	
	print STDERR "reading $file\n" unless $quiet;
	
	my $pr = ProgressBar->new(-s $file);
	
	while (<FH>) {
		
		$pr->advance(length($_));
		
		if (/<tessdata .* score="(.*?)"/) {
			
			push @res, {SCORE => $1, SOURCE => "", TARGET => ""};
		}
		if (/<phrase text="(.+?)" .* unitID="(\d+)"/) {
		
			$res[-1]{uc($1)} = $2;
		}
	}
	
	close FH;
	
	return \@res;
}

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
		
		if (defined $tess{$$_{BC_PHRASEID}}{$$_{AEN_PHRASEID}}) { $exists++ }
	}
	
	return $exists;
}


#
# output subroutines
#

sub print_detail {
	
	if ($detail) {
		for (1..5) {
			
			my $rate =  $total[$_] > 0 ? sprintf("%.2f", $count[$_]/$total[$_]) : 'NA';
			my $score = $count[$_] > 0 ? sprintf("%.2f", $score[$_]/$count[$_]) : 'NA';
			
			print join("\t", $_, $count[$_], $total[$_], $rate, $score) . "\n";
		}
	}
	
	my $rate =  $total[6] > 0 ? sprintf("%.2f", $count[6]/$total[6]) : 'NA';
	my $score = $count[6] > 0 ? sprintf("%.2f", $score[6]/$count[6]) : 'NA';
	
	print join("\t", "comm.", $count[6], $total[6], $rate, $score) . "\n";
}

sub print_html_table {
	
	@order = sort { $bench[$a]{BC_PHRASEID}  <=> $bench[$b]{BC_PHRASEID} }
				sort { $bench[$a]{AEN_PHRASEID} <=> $bench[$b]{AEN_PHRASEID} }
	
				(@order);
	
	for my $i (@order) {
		
		print join("\t", 
				   'B.C. ' . $bench[$i]{BC_BOOK}  . '.' . $bench[$i]{BC_LINE},
				   'Aen. ' . $bench[$i]{AEN_BOOK} . '.' . $bench[$i]{AEN_LINE},
				   $bench[$i]{SCORE},
				   (defined $bench[$i]{AUTH} ? join(",", @{$bench[$i]{AUTH}}) : "")
				   );
		print "\n";
	}
}