use strict;
use warnings;

use Frontier::Client;
use Data::Dumper;

my @words = @ARGV;

if ( $#words < 0 )
{
	die "Specify words to look up on command line";
}

my $lang;

if ($words[0] =~ s/^-//)
{
	if (lc $words[0] eq "grc") { $lang = "-GRC" 	}
	else								{ $lang = "-LA"	}
	shift @words;
}

my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => 1);

my $res = $client->call('lemma', $lang, [@words]);
		
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




