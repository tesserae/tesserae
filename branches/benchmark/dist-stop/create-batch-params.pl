# create a bunch of settings combinations to test out
# then split the list into four parcels for parallel
# processing on vast lab machines
#
# try to put the longest-running searches (low stoplist,
# high distance) in smaller parcels so that everything
# finishes at about the same time.

use strict;
use warnings;

my $parcels = 4;

my @settings;

for (my $dist = 5; $dist <= 40; $dist += 5) {

	for (my $stop = 120; $stop > 40; $stop -= 5) {
		
		push @settings, {dist => $dist, stop => $stop};
	}
	
	for (my $stop = 40; $stop >= 0; $stop --) {
		
		push @settings, {dist => $dist, stop => $stop};
	}
}

my $size = int(scalar(@settings)/($parcels+1));

for my $i (1..$parcels) {

	open FH, ">", "batch.$i";
	
	for (1..$size) {
	
		my %s = %{shift @settings};
		
		print FH "$s{dist}\t$s{stop}\n";
	}
	
	if ($i == $parcels) {
	
		for (0..$#settings) {
		
			my %s = %{shift @settings};
			
			print FH "$s{dist}\t$s{stop}\n";			
		}
	}
	
	close FH;
}