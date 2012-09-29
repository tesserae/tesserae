#! /usr/bin/perl

use strict;
use warnings;

use lib '/Users/chris/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use Storable;
use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);


for my $file_in (@ARGV) {		# files to parse are cmd line arguments

   ##################################
   # getting input
   ##################################

   my $short_name = $file_in;
   $short_name =~ s/^.*\///;		# remove path
   $short_name =~ s/\.tess//;		# and extension

   my $file_out = "$fs_data/v1/$short_name";

   print STDERR 'getting ' . $file_in . '...';

   open (FH, "<$file_in") || die "can't open $file_in: $!";

   my @rawdata = (<FH>);

   close FH;

   print STDERR $#rawdata . " lines\n";

   #######################################
   # clean the text
   #######################################

   print STDERR "trimming...";

   my @index_loc  = ();        		# these have to be reset since they
   my @index_verb = ();       		# might be reused in some later version

   my @words;                   		# used locally to store
   my $locus;                     		# temporary values

   for (@rawdata) {        		# for each line...

      s/<(.*)>\t//;             		# remove locus tag
      $locus = $1;                		# and save it

      $_ = lc;                  		# convert to lowercase
      tr/a-z/ /c;               		# remove all non-letters (c means complement)
      s/^\s+//;                 		# remove leading spaces
      tr/jv/iu/;				# get rid of orthographic variation

      @words = split /\s+/;     		# split on whitespace

      push @index_loc,              	# for the index locorum, just add the
             ($locus)x(scalar @words);  	# current line once for each word in it

      push @index_verb, @words;    	# add words to index verborum
   }

   print STDERR '$#index_loc=' . $#index_loc .'; $#index_verb=' . $#index_verb . "\n";


   ###################################
   # parsing into ngrams
   ###################################

   print STDERR "parsing...";

   my %ngrams;      	        # to sort them by key-pair
   my @phrase;             	# phrases ngrams capture
   my @loc;         		# loci of those phrases by first key

   my $id;                              		# unique identifier for each phrase

   for my $n (1..5) {                           	# offset of second word

      for my $i (0..$#index_verb-5) {      	# i = address of first word

         my $j = $i + $n;                       	# j = address of second word

         my $keypair = join("-",                	# join the two words to create a key;
                     sort @index_verb[$i,$j]);

         $id++;                                 	# increment id

         $loc[$id]    = $index_loc[$i];  		# locus is that of first word
         $phrase[$id] = join(" ",                  # phrase is everything between them;
                       @index_verb[$i..$j]);

         push @{$ngrams{$keypair}}, $id;		# add phrase to array filed under keypair
      }
   }

   print $#{[keys %ngrams]} . " keypairs\n";

   #######################################
   # writing output
   #######################################

   print STDERR "writing...";

   print STDERR " $file_out.ngrams"; 
   nstore \%ngrams, "$file_out.ngrams";

   print STDERR " $file_out.phrase";
   nstore \@phrase, "$file_out.phrase";

   print STDERR " $file_out.loc";
   nstore \@loc,    "$file_out.loc";

   print STDERR "\ndone\n";

   print STDERR "adding $short_name to HTML drop-down...\n";

	my $title = $short_name;
	
	$title =~ s/_/ /g;
	$title =~ s/\./ - /;

	while ($title =~ /\b([a-z])/g)
	{
		my $lc = $1;
		my $uc = uc($lc);
		$title =~ s/\b$lc/$uc/;
	}
	

	my $exec_string = qq{echo '<option value="$short_name">$title</option>' >> $fs_html/textlist.v1.php};

	print STDERR "$exec_string\n";

	`$exec_string`;

   print STDERR "done\n";

}

