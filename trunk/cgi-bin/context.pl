#! /opt/local/bin/perl5.12

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;

use Storable;
use CGI qw/:standard/;

print header;

my ($source, $line);

my %abbr = %{retrieve("$fs_data/common/abbr")};
my %lang = %{retrieve("$fs_data/common/lang")};

my $query = new CGI || die "$!";

my $flag = shift @ARGV || "";

if ($flag eq "--no-cgi") 
{

   my %temphash;

   for (@ARGV) 
	{
      /--(.+)=(.+)/;
      $temphash{lc($1)} = $2;
   }

   $source = $temphash{'source'} || die "no source";
   $line   = $temphash{'line'} 	|| die "no line";

}
else 
{
   $source = $query->param('source') || die "$!";
   $line   = $query->param('line')   || die "$!";
}


my $pre_ref;

$source =~ s/\.part\..*//; 

unless ($flag eq "--no-cgi")
{
   print <<END;
   <html>
   <head><title>$source</title></head>
   <body>
      <center>
      <table>
END
}

my $file = "$fs_text/$lang{$source}/$source.tess";

my $context = `grep -C4 \"<$abbr{$source} $line>\" $file`;

my @context = split /\n/, $context;

for (@context) {

   next if /^$/;

   my $mark = "";
	my $col_l = "";
	my $col_r = "";
   my $row_l = "";
	my $row_r = "";
	my $ln = "";

   s/<$abbr{$source} //;		# the work and author
   s/      (   [0-9a-z]+\.  )*	# $1 = optional book, poem numbers;
           (   [0-9]+       )		# $2 = just the line no.		
     >//x;

   my $long  = $1.$2;
   my $pre   = $1;
   my $short = $2;

   if ($flag eq "--no-cgi") {
      if ($long eq $line ) { $mark = ">" }
      $col_l = "";
      $col_r = "\t";
      $row_l = "";
      $row_r = "\n";
   }
   else {
      if ($long eq $line) { $mark = "&#9758;" }
      $col_l = "<td>";
      $col_r = "</td>";
      $row_l = "      <tr>";
      $row_r = "</tr>\n";
   }

   if ($short % 5 == 0) {$ln = $long}

   print "$row_l $col_l $mark $col_r $col_l $ln $col_r $col_l $_ $col_r $row_r";
}

unless ($flag eq "--no-cgi") {
   print <<END;
     </table>
     </body>
   </html>
END
}
