use strict;
use warnings;

use Storable;

my $cache_file = 'data/common/la.stem.cache';

my %cache = %{retrieve($cache_file)};

my @files = @ARGV;

my %count;
my %total;

for my $file (@files)
{

	print STDERR "$file\n";

	open (TEXT, "<", $file);

	while (my $line = <TEXT>)
	{
		for ($line)
		{
			s/\<(.+)\>\s*(.*)/$2/s;
                        tr/A-Z/a-z/;    # convert all to lowercase
                        tr/A-Za-z/ /cs;  # remove all non-alpha/phrase-punct chars
                        s/^\s+//;       # remove leading space 
                        s/\s+$//;       # remove trailing space
		}

		next if ($line !~ /[a-z]/);

		my @word = split(/ /, $line);

		for (@word)
		{
			next unless (exists $cache{$_});
			
			my @stem = @{$cache{$_}};

			for (@stem)
			{
				$count{$_}{$file}++;
				$count{$_}{'total'}++;
			}
		}
	}

	close (TEXT);

}


my $longest = 0;

for (keys %count)
{
	if (length($_) > $longest) { $longest = length($_) }
}

$longest += 1;

print sprintf("%-${longest}s", "stem") . "total\t" . join ("\t", @files) . "\n";

for my $stem (sort { $count{$b}{'total'} <=> $count{$a}{'total'} } keys %count)
{
	print sprintf("%-${longest}s", "\"$stem\"") . $count{$stem}{'total'};

	for my $file (@files)
	{
		print "\t";
		print $count{$stem}{$file} || 0;
	}

	print "\n";
}

