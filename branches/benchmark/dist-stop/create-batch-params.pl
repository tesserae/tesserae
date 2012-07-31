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

	for (my $stop = 0; $stop < 40; $stop ++) {
		
		push @settings, {dist => $dist, stop => $stop};
	}
	
	for (my $stop = 40; $stop <= 120; $stop += 5) {
		
		push @settings, {dist => $dist, stop => $stop};
	}	
}

my $defaultsize = int(scalar(@settings) / $parcels);


for my $i (1..$parcels) {
	
	my $size;
	
	if    ($i == 0)        { $size = int($defaultsize/2) }
	elsif ($i != $parcels) { $size = $defaultsize }
	else                   { $size = scalar(@settings) }

	open FH, ">", "batch.$i";
	
	for (1..$size) {
	
		my %s = %{shift @settings};
		
		print FH "$s{dist}\t$s{stop}\n";
	}
	
	close FH;
}