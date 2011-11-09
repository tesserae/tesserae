use lib '/var/www/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use Frontier::Client;
use Storable qw(retrieve nstore);
use Files;

my @files = @ARGV;

my $lookup = 0;
my $write_cache = 0;

my $file_cache = Files::cache_filename();
 
my %count;

for my $file (@files)
{

	print "parsing $file\n";

        open (TEXT, $file) || die "Can't open $file";

        while (<TEXT>) {

                chomp;

                my $verse = $_;

                for ($verse)
                {
                        s/\<(.+)\>\s*(.*)/$2/s;
                        #tr/A-Z/a-z/;    # convert all to lowercase
                        tr/A-Za-z/ /cs;  # remove all non-alpha/phrase-punct chars
                        s/^\s+//;       # remove leading space 
                        s/\s+$//;       # remove trailing space
		}

                my @words = split(' ', $verse);

                foreach (@words)
                {
                        $count{$_}++;
                }
        }
        close (TEXT);

}

my @wordlist = sort { $count{$b} <=> $count{$a} } keys %count;

print sprintf("%i", scalar(@wordlist)) . " forms total.\n";

##
##  Now look up each unique form --
##    first in the local cache
##    then at archimedes
##

my @archimedes;  			# batch wordlist to look up remotely

print "using cache $file_cache\n";
my %cache = %{retrieve("$file_cache")};

print "Checking cache.\n\n";

for my $w (@wordlist)
{
	unless ( defined( $cache{lc($w)} ) )
	{
		push @archimedes, $w;

#		print "$w\t$count{$w}\n";
	}
}

my @failed;

if ($lookup == 1)
{

	print sprintf("%i", scalar(@archimedes)) . " to look up on archimedes.\n\n";

	while (my @batch = splice(@archimedes, 0, 20))
	{
		my @failed_first_try;

		my %lookup = %{lookup(@batch)};

		for my $w ( @batch )
        	{

                	if ( ( defined $lookup{$w} ) and ($lookup{$w} ne ""))
                	{
                        	$cache{lc{$w} = $lookup{$w};
                	}
                	else
                	{
                        	$cache{lc($w)} = [""];
                        	push @failed_first_try, $w;
                	}
        	}

		for my $w ( @failed_first_try)
		{
			%lookup = %{lookup(variants($w))}

			if ( scalar (keys (%lookup) < 0 )
			{
				push @failed, $w;
			}
			else
			{
				for ( keys %lookup )
				{
					push @{$cache{$w}}, @{$lookup{$_}};
				}
			}
		}

		if ($write_cache == 1)
		{
			nstore \%cache, "$cache_file";
		}

		print sprintf("%i", scalar(@archimedes)) . " remain.\n";
	}
}
else 
{
	@failed = @archimedes;
}

print sprintf("%i", $#failed+1) . " failed:\n";

for (@failed)
{
	print "$_\n";
}

sub variants
{
	my $word = shift;

	my @variants;

	

	for ($word)
	{
		tr/A-Z/a-z/;
		push @variants, $_;

		s/a-z/A-Z/;
		push @variants, $_;

		tr/A-Z/a-z/;
		tr/jv/iu/;
		push @variants, $_;

		s/([aeiou])u([aeiou])/$1v$2/g;
		push @variants, $_;
	}
}

sub lookup
{
	my @batch = @_;

	my @failed = ();

	print "looking up " . join (", ", @batch) . ";" ;

	my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => 0);

	my $res = $client->call('lemma', "-LA", [@batch]);

	return $res;
}

