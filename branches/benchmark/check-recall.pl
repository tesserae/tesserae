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
my $detail = 0;

GetOptions("cache=s" => \$file_cache, "verbose|detail" => \$detail);

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

if ($detail) {
	
	my ($cref, $tref) = score(\@bench, \%tess);
	
	my @count = @$cref;
	my @total = @$tref;
	
	for (1..5) {
		
		my $rate = $total[$_] > 0 ? sprintf("%.2f", $count[$_]/$total[$_]) : 'NA';
	
		print "$_\t$count[$_]\t$total[$_]\t$rate\n";
	}
	
}
else {
	
	my $found = compare(\@bench, \%tess);

	print "found $found/" . scalar(@bench) . " or " . sprintf("%02i%%", 100*$found/scalar(@bench)) . ".\n";
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

sub score {
	
	my ($benchref, $tessref) = @_;
	
	my @bench = @$benchref;
	my %tess  = %$tessref;
	
	my %in_tess;
	my @count = (0)x6;
	my @total = (0)x6;
	
	print STDERR "comparing\n" unless $quiet;
		
	for (@bench) {
		
		$total[$$_{SCORE}]++;
		
		if (defined $tess{$$_{BC_PHRASEID}}{$$_{AEN_PHRASEID}}) { 
			
			$count[$$_{SCORE}]++;
		}
	}
		
	return (\@count, \@total);
}
