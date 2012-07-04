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

# different stoplist settings

my @list;

for (my $s = 0; $s <= 250; $s += ($s >= 10 ? 5 : 1)) { push @list, $s }

# run all the stoplists

for my $i (0..$#list) {
	
	my $stop = $list[$i];
	
	print STDERR "running test " . sprintf("%i/%i", $i+1, $#list+1) . "...\n";
	
	docmd("perl $fs_cgi/read_table.pl --target lucan.pharsalia.part.1 --source vergil.aeneid --no-cgi --feature $feature --unit $unit --stopwords $stop > .tesresults.xml");
	
	my $n = docmd("grep -c '<tessdata ' .tesresults.xml");
	chomp $n;
	
	my $hits = docmd("perl check-recall.pl .tesresults.xml");
	$hits =~ /found (\d+)\//;
	$hits = $1;
	
	print join("\t", $i, $stop, $n, $hits) . "\n";
}

sub docmd {

	my $cmd = shift;
	
	print STDERR "$cmd\n";

	my $res = `$cmd`;
	
	print STDERR $res;	
	
	return $res;
}
