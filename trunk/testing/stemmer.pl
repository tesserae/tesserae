use strict;
use warnings;

use lib "/usr/local/perl/lib/perl5/site_perl/5.8.8/";
use Lingua::LA::Stemmer;

while (my $line =<>) {

   chomp $line;

   my @words = split (/\s+/, $line);

   print join(",", Lingua::LA::Stemmer::stem(\@words)) . "\n";

}
