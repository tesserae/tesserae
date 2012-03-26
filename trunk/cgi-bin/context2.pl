#! /usr/bin/perl

use lib '/var/www/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;

use Storable;
use CGI qw/:standard/;

print header;

my ($target, $line);

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

   $target = $temphash{'target'} || die "no target";
   $line   = $temphash{'line'} 	|| die "no line";

}
else 
{
   $target = $query->param('target') || die "$!";
   $line   = $query->param('line')   || die "$!";
}


unless ($flag eq "--no-cgi")
{
   print <<END;
   <html>
   <head><title>$target</title></head>
   <body>
      <center>
      <table>
END
}


#
# load the database for target text
#

my @word = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.word" )};
my @unit_target = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.line" ) };
my @loc_target  = @{ retrieve( "$fs_data/v3/$lang{$target}/word/$target.loc_line" ) };

# context begins 5 lines before the target line, ends five lines after

my $start = $line >= 5 ? $line - 5 : 0;
my $end = ($line + 5) <= $#unit_target ? $line + 5 : $#unit_target;

# display the text

for my $ref_ext ($start..$end)
{
	my $display;
	
	for my $i (0..$#{$unit_target[$ref_ext]{WORD}})
	{
		my $w = ${$unit_target[$ref_ext]{WORD}}[$i];
		
		my $word_ = $word[$w];

		$display .= ${$unit_target[$ref_ext]{SPACE}}[$i] . $word_;
	}
	
	$display .= ${$unit_target[$ref_ext]{SPACE}}[$#{$unit_target[$ref_ext]{SPACE}}];
	
	my $mark = "";
	my $col_l = "";
	my $col_r = "";
	my $row_l = "";
	my $row_r = "";
	my $ln = "";

	if ($flag eq "--no-cgi") {

		if ($ref_ext == $line ) { $mark = ">" }
		$col_l = "";
		$col_r = "\t";
		$row_l = "";
		$row_r = "\n";
	}
	else {
		
		if ($ref_ext == $line) { $mark = "&#9758;" }
		$col_l = "<td>";
		$col_r = "</td>";
		$row_l = "      <tr>";
		$row_r = "</tr>\n";
   }

   print join(" ", $row_l, $col_l, $mark, $col_r, $col_l, $loc_target[$ref_ext], $col_r, $col_l, $display, $col_r, $row_r);
}

unless ($flag eq "--no-cgi") {
   print <<END;
     </table>
     </body>
   </html>
END
}
