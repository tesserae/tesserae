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

use lib '/Users/chris/Sites/tesserae/perl';
use EasyProgressBar;

my $usage = "usage: perl check-recall [--cache CACHE] TESRESULTS\n";

#
# set up the files we're going to use
#

my $file_cache = "data/commentators.cache";
my $file_tess  = shift @ARGV;

unless (defined $file_tess) {
	
	print STDERR $usage;
	exit;
}

GetOptions("cache=s" => \$file_cache);

#
# read the data
#

my @bench = @{ retrieve($file_cache) };

my @tess = @{ readTess($file_tess) };

#
# compare 
#

my $found = compare(\@bench, \@tess);

print "found $found/" . scalar(@bench) . " or " . sprintf("%02i%%", 100*$found/scalar(@bench)) . ".\n";

#
# subroutines
#

sub readTess {

	my $file = shift;
	
	my @res;
	
	open(FH, "<:utf8", $file) || die "can't read $file: $!";
	
	print STDERR "reading $file\n";
	
	my $pr = ProgressBar->new(-s $file);
	
	while (<FH>) {
		
		$pr->advance(length($_));
		
		if (/<tessdata .* score="(\d+)"/) {
			
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
	my @tess  = @$tessref;
	
	my %in_tess;
	my $exists = 0;
	
	print STDERR "comparing\n";
	
	my $pr = ProgressBar->new(scalar(@tess) + scalar(@bench));
	
	for (@tess) {
		
		$pr->advance();
	
		$in_tess{$$_{TARGET}}{$$_{SOURCE}} = $$_{SCORE};
	}
	
	for (@bench) {
	
		$pr->advance();
		
		if (defined $in_tess{$$_{BC_PHRASEID}}{$$_{AEN_PHRASEID}}) { $exists++ }
	}
	
	return $exists;
}
