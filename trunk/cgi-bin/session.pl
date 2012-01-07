#!/usr/bin/perl

use lib '/Users/chris/sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;

use Storable;
use CGI qw/:standard/;

########################################
# html header
########################################

print header;

my $stylesheet = "$url_css/style.css";

print <<END;

<html>
<head>
   <title>Tesserae results</title>
   <link rel="stylesheet" type="text/css" href="$stylesheet" />

END

########################################
# variables
########################################

my @index_loc_source;           # array containing one locus per word
my @index_loc_target;           #

my @index_verb_source;          # array containing all words in order
my @index_verb_target;          #

my %ngrams_source;              # to sort them by key-pair
my %ngrams_target;              #

my @phrase_source;              # phrases ngrams capture
my @phrase_target;              #

my @loc_source;         # loci of those phrases by first key
my @loc_target;         #

my $stoplist;

my %abbr = %{retrieve("$fs_data/common/abbr")};

##################################
# begin a new session
##################################

opendir(my $dh, $fs_tmp) || die "can't opendir $fs_tmp: $!";

my @tes_sessions = grep { /^tesresults-[0-9a-f]{8}\.xml/ && -f "$fs_tmp/$_" } readdir($dh);
closedir $dh;

@tes_sessions = sort(@tes_sessions);

my $session = $tes_sessions[$#tes_sessions];

if (defined($session)) 
{
	$session =~ s/^.+results-//;
	$session =~ s/\.xml//;
}
else
{
	$session = "0" 
}

$session = sprintf("%08x", hex($session)+1);

my $session_file = "$fs_tmp/tesresults-$session.xml";

open (XML, '>' . $session_file)
	|| die "can't open " . $session_file . ':' . $!;


##################################
# getting input
##################################

my $query = new CGI || die "$!";

my $source = $query->param('source') || "";
my $target = $query->param('target') || "";
my $match  = $query->param('unit')   || "";
my $cutoff = $query->param('cutoff') || 10;
my $stopwords = $query->param('stopwords') || "";

my $hash_path = "$fs_data/v1";

if ($match eq "stem") 		{ $hash_path .= "/stem" }

if ($source eq "")
{
	$source = shift @ARGV;
	$target = shift @ARGV;
}



for ($stopwords) {

   tr/A-Z/a-z/;
   tr/a-z/ /c;
   s/^\s+//sg;
   s/\s+/ /sg;
}

$stoplist = join(" ", @{$top{"la_$match"}}[0..$cutoff-1]) || "";

if ($stopwords ne "") { $stoplist .= " $stopwords" }

%ngrams_source = %{	retrieve("$hash_path/$source.ngrams") };
@phrase_source = @{	retrieve("$hash_path/$source.phrase") };
@loc_source    = @{	retrieve("$hash_path/$source.loc")    };

%ngrams_target = %{	retrieve("$hash_path/$target.ngrams") };
@phrase_target = @{	retrieve("$hash_path/$target.phrase") };
@loc_target    = @{	retrieve("$hash_path/$target.loc")    };



###################################################
# finding common ngrams
###################################################

for (keys %ngrams_source) 
{
   my ($a,$b) = split(/-/);

   if (($stoplist =~ /\b$a\b/) 
	or ($stoplist =~ /\b$b\b/))	{ delete $ngrams_source{$_} }
}

my @common_keypairs = @{&intersection( \@{[keys %ngrams_source]},
                                \@{[keys %ngrams_target]}   )};

print STDERR scalar(@common_keypairs) . " common keypairs\n";

##################################################
# format output
##################################################

print XML "<results source=\"$source.tess\" target=\"$target.tess\" sessionID=\"$session\">\n";
print XML "   <comments>Version 1 results</comments>\n";
print XML "   <commonwords>" . join(", ", split (/\s+/, $stoplist)) . "</commonwords>\n";

for (@common_keypairs) 
{

   my $keypair = $_;
   $keypair =~ s/-/, /;

   print XML "   <tessdata keypair=\"$keypair\" score=\"NA\">\n"; 

   my @temp_array_source = @{$ngrams_source{$_}};
   my @temp_array_target = @{$ngrams_target{$_}};

   for (@temp_array_source) {

   	my $loc_source = $loc_source[$_];

   	my $shortline 	= $loc_source;
           $shortline	=~ s/$abbr{$source} //;

      	print XML "      <phrase"
							. " text=\"source\""
 							. " work=\"$abbr{$source}\""
 							. " line=\"$shortline\""
							. " link=\"$url_cgi/context.pl?source=$source;line=$shortline\">"

							. $phrase_source[$_]

							. "</phrase>\n";
   }

   for (@temp_array_target) {

   	my $loc_target = $loc_target[$_];

         my $shortline 	= $loc_target;
            $shortline	=~ s/$abbr{$target} //;
         
         print XML "      <phrase "
                    . " text=\"target\""
                    . " work=\"$abbr{$target}\""
                    . " line=\"$shortline\""
                    . " link=\"$url_cgi/context.pl?source=$target;line=$shortline\">"
                    
                    . $phrase_target[$_]

                    . "</phrase>\n";
   }

   print XML "   </tessdata>\n";
}

print XML "</results>\n";

close XML;


########################################
# redirect web browser to results
########################################

my $redirect = "$url_cgi/get-data.pl?session=$session;sort=target";

print <<END;
   <meta http-equiv="Refresh" content="0; url='$redirect'">
</head>
<body>
   <p>
      Please wait for your results until the page loads completely.  
      <br/>
      If you are not redirected automatically, 
      <a href="$redirect">click here</a>.
   </p>
</body>
</html>
END


########################################
# subroutines
########################################

sub uniq {                      # return unique values of an array as
				# a reference to a new array

   my @array = @{$_[0]};        # dereference array to be evaluated

   my %hash;	# temporary
   my @uniq;	# create a new array to hold return value

   @hash{@array} = ();          # every element of array provides a key to hash, 
				# duplicates overwrite each other

   @uniq = sort( keys %hash);   # retrieve keys, sort them

   return \@uniq;
}


sub intersection {              

	# arguments are any number of arrays,
	# returns elements common to all as 
	# a reference to a new array

   my %count;			# temporary, local
   my @intersect;		# create the new array

   for my $array (@_) {         # for each array

      for (@$array) {           # for each of its elements (assume no dups)
         $count{$_}++;          # add one to count
      }
   }

   @intersect = grep { $count{$_} == 2 } keys %count;  
				# keep elements whose count is equal to the number of arrays

   @intersect = sort @intersect;        # sort results

   return \@intersect;
}

sub popup {
   my ($source, $line, $text) = @_[0..2];

   my $link = '<a href="javascript:;" onclick="window.open('
	. "'" . $url_cgi. "/context.pl?source=" . $source . ";line=" . $line . "'"
	. ",'headings','width=520,height=240');\">" . $text . "</a>";
   return $link;
}

   

