#
# perform a whole lot of tesserae searches on lucan book 1 vs aeneid
# and compare the number of commentator hits for different stop-lists
#

use strict;
use warnings;

use lib '/Users/chris/tesserae/perl';
use TessSystemVars;
use EasyProgressBar;

use Getopt::Long;


# 
# settings
#

my $feature = "stem";
my $unit    = "phrase";
my $stoplist_basis = "corpus";
my $distance_metric = "span";
my $debug = 0;

GetOptions( 
	"feature=s" => \$feature,
	"unit=s"    => \$unit,
	"stbasis=s" => \$stoplist_basis,
	"dibasis=s" => \$distance_metric,
	"debug|verbose" => \$debug
	);

my $file = shift @ARGV || die "specify file to run\n";

my @run = @{ReadFile($file)};

#
# run tesserae a bunch of times
#

my $pr = ProgressBar->new(scalar(@run), $debug);

for (@run) {
	
	my $stop = $$_{stop};
	my $dist = $$_{dist};
	
	$pr->advance(1, $debug);
		
	if ($debug) {
		
		print STDERR "running test " . sprintf("%i/%i", $pr->progress(), $pr->terminus()) . "...\n";
	}
	
	# run tesserae search
	
	docmd("$fs_cgi/read_table.pl --target lucan.pharsalia.part.1 --source vergil.aeneid"
		  . " --no-cgi --feature $feature --unit $unit --stopwords $stop --dist $dist"
		  . " --dibasis $distance_metric --stbasis $stoplist_basis"
		  . ($debug ? "" : " --quiet")
		  . " --bin $file.tesresults.bin");
			
	# check the results
	
	my $detail = docmd("perl check-recall.pl -d $file.tesresults.bin");
	
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
		
		if ($score eq "comm.") { $score = 6 }
		
		$hits[$score] = $hits;
		$rate[$score] = $rate;
	}
		
	print join("\t", $stop, $dist, $n, @hits[1..6]) . "\n";
}

docmd("rm $file.tesresults.bin");

sub docmd {

	my $cmd = shift;
	
	print STDERR "$cmd\n" if $debug;

	my $res = `$cmd`;
	
	print STDERR $res if $debug;
	
	return $res;
}

sub ReadFile {

	my $file = shift;
	
	open (FH, "<", $file) || die "can't read $file: $!";
	
	my @run;
	
	while (my $line = <FH>) {
		
		next unless $line =~ /(\d+)\s+(\d+)/;
		
		push @run, {dist => $1, stop => $2};
	}
	
	return \@run;
}