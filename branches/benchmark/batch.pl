#
# perform a whole lot of tesserae searches on lucan book 1 vs aeneid
# and compare the number of commentator hits for different stop-lists
#

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';
use TessSystemVars;
use EasyProgressBar;

# static settings

my $feature = "stem";
my $unit    = "phrase";

# 
#
#

my $debug = 0;

my $pr = ProgressBar->new(51 * 10, $debug);

for (my $stop = 0; $stop <= 250; $stop += 5) {
	
	for (my $dist = 50; $dist >=5; $dist -= 5) {
		
		$pr->advance(1, $debug);
		
		if ($debug) {
		
			print STDERR "running test " . sprintf("%i/%i", $pr->progress(), $pr->terminus()) . "...\n";
		}
		
		# run tesserae search
		
		docmd("$fs_cgi/read_table.pl --target lucan.pharsalia.part.1 --source vergil.aeneid"
			  . " --no-cgi --feature $feature --unit $unit --stopwords $stop --dist $dist"
			  . ($debug ? "" : " --quiet"));
				
		# check the results
		
		my $detail = docmd("perl check-recall.pl -d tesresults.bin");
		
		# parse the information returned by check-recall
		
		my @line = split/\n/, $detail;
		
		# first the number of tess results
		
		$line[0] =~ /tesserae returned (\d+) results/;
					  
		my $n = $1;
		
		# now the recall data for each type
		
		my @hits;
		my @rate;
		
		for (@line[1..6]) {
			
			my ($score, $hits, $total, $rate) = split /\t/;
			
			$hits[$score] = $hits;
			$rate[$score] = $rate;
		}
			
		print join("\t", $stop, $dist, $n, @hits[1..6]) . "\n";
	}
}

sub docmd {

	my $cmd = shift;
	
	print STDERR "$cmd\n" if $debug;

	my $res = `$cmd`;
	
	print STDERR $res if $debug;
	
	return $res;
}
