use strict;
use warnings;

use Frontier::Client;
use Data::Dumper;

my @words = @ARGV;

if ( $#words < 0 )
{
	die "Specify words to look up on command line";
}

my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => 1);

my $res = $client->call('lemma', "-LA", [@words]);
		
print Dumper($res) . "\n";
		
for my $w (@words)
{
	print "$w: ";
	
	if ( defined $res->{$w} )
	{
		my $test = $res->{$w};

		print join (" ", @{$test}) . "\n";			
	}
	else
	{
		print "! lookup $w failed";
	}

	print "\n";
}




