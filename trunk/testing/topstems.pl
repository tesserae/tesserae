use strict;
use warnings;

use lib "/usr/local/perl/lib/perl5/site_perl/5.8.8/";
use Lingua::LA::Stemmer;

my @files = @ARGV;

my %count;
my $total;
my $cumul;
my $max;

for (@files) {

   print STDERR "$_\n";

   open (FH, $_) || next;

   for (<FH>) {
   
      my $line=$_;

      chomp;

      s/<.+>//;

      tr/A-Z/a-z/;
      tr/jv/iu/;
      s/[^a-z ]//g;
      s/\s+/ /;
      s/^ //;

      my @words = split(/\s{1,}/);

      next if ($#words < 0 );

      for (Lingua::LA::Stemmer::stem(\@words)) { 
         $count{$_}++;
         $total++;
         if (length($_) > $max) { $max = length($_) }
      }
   }
   close FH;
}


for (sort { $count{$b} <=> $count{$a} } keys %count) {

   $cumul += $count{$_}/$total;

   print sprintf("%-".$max."s\t%.5f\t%.5f\n", $_, $count{$_}/$total, $cumul); 
}
