#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/perl/lib/perl5/site_perl/5.8.8/";
use Lingua::LA::Stemmer;        #latin stemmer
use Storable;


for my $file_in (@ARGV) {		# files to parse are cmd line arguments

   #################################3
   # getting input
   ##############################3###

   my $short_name = $file_in;
   $short_name =~ s/^.*\///;		# remove path
   $short_name =~ s/\.tess//;		# and extension

   my $file_out = "/var/www/html/tesserae/tess_hash/stem/$short_name";

   print "getting $file_in...";

   open (FH, "<$file_in") || die "can't open file: $!";

   my @rawdata = <FH>;

   close FH;

   print "$#rawdata lines\n";

   #######################################
   # clean the text
   #######################################

   print "trimming, stemming...";

   my @index_loc  = ();    
   my @index_verb = ();   
   my @index_stem = ();

   my @words;                   		# used locally to store
   my @stems;
   my $locus;                     		# temporary values

   for (@rawdata) {        		# for each line...

      s/<(.*)>\t//;             		# remove locus tag
      $locus = $1;                		# and save it

      $_ = lc;                  		# convert to lowercase
      tr/a-z/ /c;               		# remove all non-letters (c means complement)
      s/^\s+//;                 		# remove leading spaces
      tr/jv/iu/;				# get rid of orthographic variation

      @words = split /\s+/;     		# split on whitespace

      @stems = @{Lingua::LA::Stemmer::stem(\@words)};

      push @index_loc,              	# for the index locorum, just add the
             ($locus)x(scalar @words);  	# current line once for each word in it

      push @index_verb, @words;    	# add words to index verborum
      push @index_stem, @stems;		# add stems to index stemmarum
   }

   print "\$#index_loc=$#index_loc; \$#index_verb=$#index_verb; \$#index_stem=$#index_stem\n";


   ###################################
   # parsing into ngrams
   ###################################

   print "parsing...";

   my %ngrams;      	        # to sort them by key-pair
   my @phrase;             	# phrases ngrams capture
   my @loc;         		# loci of those phrases by first key

   my $id;                              		# unique identifier for each phrase

   for my $n (1..5) {                           	# offset of second word

      for my $i (0..$#index_verb-5) {           	# i = address of first word

         my $j = $i + $n;                       	# j = address of second word

         my $keypair = join("-",                	# join the two words to create a key;
                     sort @index_stem[$i,$j]);

         $id++;                                 	# increment id

         $loc[$id]    = $index_loc[$i];  		# locus is that of first word
         $phrase[$id] = join(" ",    	                # phrase is everything between them;
                       @index_verb[$i..$j]);

         push @{$ngrams{$keypair}}, $id;		# add phrase to array filed under keypair
      }
   }

   print "$#{[keys %ngrams]} keypairs\n";

   #######################################
   # writing output
   #######################################

   print "writing $file_out...";

   store \%ngrams, "$file_out.ngrams";
   store \@phrase, "$file_out.phrase";
   store \@loc,    "$file_out.loc";

   print "done\n";

}
