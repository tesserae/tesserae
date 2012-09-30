#! /usr/bin/perl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;

use Storable;
use CGI qw/:standard/;
use Getopt::Long;

my ($target, $unit, $id);
my $no_cgi = 0;

# get options from command line

GetOptions('no-cgi' => \$no_cgi, 'target=s' => \$target, 'unit=s' => \$unit, 'id=i' => \$id);

# Get further options from cgi interface if appropriate

unless ($no_cgi) {
	
	print header('-charset'=>'utf-8', '-type'=>'text/html');

	my $query = new CGI || die "$!";

   $target = $query->param('target') || $target;
   $unit   = $query->param('unit')   || $unit;
   $id     = $query->param('id')     || $id;

   print <<END;
   <html>
   <head><title>$target</title></head>
   <body>
      <center>
      <table>
END
}

#
# load resources
#

my %abbr = %{retrieve("$fs_data/common/abbr")};
my %lang = %{retrieve("$fs_data/common/lang")};

my @token  = @{ retrieve( "$fs_data/v3/$lang{$target}/$target/$target.token" )};
my @line   = @{ retrieve( "$fs_data/v3/$lang{$target}/$target/$target.line" ) };
my @phrase = $unit ne 'phrase' ? () :
             @{ retrieve( "$fs_data/v3/$lang{$target}/$target/$target.phrase" ) };

#
# generate context
#

my @lines;

# if the unit is phrase, then start with all the lines the phrase covers

if ($unit eq 'phrase') { 
	
	@lines = @{$phrase[$id]{LINE_ID}};
	$id = $lines[0];
}

# if the unit is lines, then start with the line itself

else {

	@lines = ($id);
}

# if the context is fewer than 10 lines, then add some
# to the beginning and the end.

if ($#lines < 9) {
	
	my $needed = int((10 - $#lines)/2);

	my $start = $lines[0] >= 5 ? $lines[0] - 5 : 0;
	my $end = ($lines[-1] + 5) <= $#line ? $lines[-1] + 5 : $#line;
	
	@lines = ($start..$end);
}

# display the text

for my $line_id (@lines) {

	my $display;
	
	for my $token_id (@{$line[$line_id]{TOKEN_ID}}) {
		
		$display .= $token[$token_id]{DISPLAY}
	}
	
	my $mark = "";
	my $col_l = "";
	my $col_r = "";
	my $row_l = "";
	my $row_r = "";
	my $ln = "";

	if ($no_cgi) {
		
		if ($line_id == $id ) { $mark = ">" }
		$col_l = "";
		$col_r = "\t";
		$row_l = "";
		$row_r = "\n";
   }
	else {
		
		if ($line_id == $id) { $mark = "&#9758;" }
		$col_l = "<td>";
		$col_r = "</td>";
		$row_l = "      <tr>";
		$row_r = "</tr>\n";
	}
	
   print join(" ", $row_l, $col_l, $mark, $col_r, $col_l, $line[$line_id]{LOCUS}, $col_r, $col_l, $display, $col_r, $row_r);
}

unless ($no_cgi) {
   print <<END;
     </table>
     </body>
   </html>
END
}
