use strict;
use warnings;

for (my $dist = 30; $dist >=5; $dist -= 5) {

	for (my $stop = 0; $stop <= 20; $stop++) {
	
		print "$dist\t$stop\n";
	}

	for (my $stop = 25; $stop <= 100; $stop += 5) {
	
		print "$dist\t$stop\n";
	}
}