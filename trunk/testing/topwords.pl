use strict;
use warnings;

my @files = @ARGV;

my %count;
my $total;
my $cumul;
my $max;

for (@files) {

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

      for (@words) { 
         $count{$_}++; 
         $total++;
         if (length($_) > $max) { $max = length($_) }
      }
   }
}


for (sort { $count{$b} <=> $count{$a} } keys %count) {

   $cumul += $count{$_}/$total;

   print sprintf("%-".$max."s\t%.5f\t%.5f\n", $_, $count{$_}/$total, $cumul); 
}
