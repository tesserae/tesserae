#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Desktop/tesserae/perl';	# PERL_PATH

#
# 3gr.test.pl
#
# visualize 3-gram frequencies
#

use strict;
use warnings;

use CGI::Session;
use CGI qw/:standard/;

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);

use TessSystemVars;
use EasyProgressBar;

#
# initialize set some parameters
#

# text to parse 

my $target = 0;

# unit

my $unit = 'line';

# length of memory effect in units

my $memory = 10;

# used to calculated the decay exponent

my $decay = .5;

# print debugging messages to stderr?

my $quiet = 0;

# 3-grams to look for; if empty, use all available

my $keys = 0;

# choose top n 3-grams

my $top = 0;

# for progress bars

my $pr;

# scaling factor

my $scale = 30;

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs_data, 'common', 'abbr');
my %abbr = %{retrieve($file_abbr)};

# language database

my $file_lang = catfile($fs_data, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

#
# initialize cgi, session objects
#

my $cgi = CGI->new() || die "$!";

my $session = CGI::Session->new(undef, $cgi, {Directory => '/tmp'});

# print header

my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
print $session->header(%h);

#
# load the matrix, keys
#

my $kref   = $session->param("keys");
my @keys   = @$kref;

my $mref   = $session->param("matrix");
my @matrix = @$mref;

#
# load the red, green, blue assignments
#

my @assign = (
				$cgi->param("red"),
				$cgi->param("green"),
				$cgi->param("blue")
			);

for (@assign) {

	if ( not defined $_ or $_ !~ /\d/ ) { $_ = -1 }
}

#
# two output modes:
#
# for the left frame, an overview with
# simple blocks of colour for the units
#
# for the right frame, a line-by-line
# display of the poem's full text.
#

$target = $session->param("target");
$unit   = $session->param("unit");

my $mode = $cgi->param("mode") || 'top';

# for future reference

my $assign = "red=$assign[0];green=$assign[1];blue=$assign[2]";

# print content according to mode (left/right)

if ($mode eq 'left') {

	print_left();

}
elsif ($mode eq 'right') {

	print_right();
}
elsif ($mode eq 'top') {

	print_top();
}


#
# subroutines
#

sub print_top {

	print <<END;
	
	<html lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="author" content="Neil Coffee, Jean-Pierre Koenig, Shakthi Poornima, Chris Forstall, Roelant Ossewaarde">
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin">
		<meta name="description" content="Intertext analyzer for Latin texts">
		<link href="$url_css/style.css" rel="stylesheet" type="text/css"/>
		<link href="$url_image/favicon.ico" rel="shortcut icon"/>

		<title>Tesserae</title>

	</head>

	<frameset cols="50%,50%">
		<frame name="left"  src="$url_cgi/3gr.display.pl?mode=left;$assign">
		<frame name="right" src="$url_cgi/3gr.display.pl?mode=right;$assign">
	</frameset>
</html>

END

	

}

sub print_left {

	# create a hash pointing each key to its index in the array

	my %labels;
	
	for (0..$#keys) {

		$labels{$_} = $keys[$_];
	}
	
	# a special value for "no assignment"

	$labels{-1} = 'none';

	# numeric values for the choices
	
	my @values = (-1..$#keys);

	# the values for red green and blue

	my $red   = $assign[0] >= 0 ? $keys[$assign[0]] : 'none';
	my $green = $assign[1] >= 0 ? $keys[$assign[1]] : 'none';
	my $blue  = $assign[2] >= 0 ? $keys[$assign[2]] : 'none';

	# the drop-down menus

	my $menu_r = popup_menu('red',   \@values, $assign[0], \%labels);
	my $menu_g = popup_menu('green', \@values, $assign[1], \%labels);
	my $menu_b = popup_menu('blue',  \@values, $assign[2], \%labels);

	#
	# load the template
	#

	my $template = `php -f $fs_html/frame.fullscreen.php`;

	# add special style 
	
	my $style = "
		<style type=\"text/css\">
			div.colour_blocks {

				color:white;
				background-color:black;
			}
			div.colour_blocks span {

				float:left;
				padding-left:10px;
				height:15px;
			}
		</style>\n";
	
	$template =~ s/<!--head-->/$style/;

	# navigation

	my $nav = "
			<p>
				<a href=\"$url_html/experimental.php\" target=\"_top\">Back to Tesserae</a>.
			</p>
			
			<h2>Options:<h2>
			
			<form action=$url_cgi/3gr.display.pl target=\"_top\" method=POST>
				<table>
					<tr><td>red  </td><td>$menu_r</td><td></td></tr>
					<tr><td>green</td><td>$menu_g</td><td><input type=\"submit\" value=\"Change\"></td></tr>
					<tr><td>blue </td><td>$menu_b</td><td></td></tr>
				</table>
			</form>";

	#
	# the visualization
	#
	
	my $blocks = "\n<div class=\"colour_blocks\">\n";

	for my $line_id (0..$#matrix) {
	
		my @row = @{$matrix[$line_id]};
		
		my @rgb = @assign;
		
		for (@rgb) {
		
			$_ = $_ >= 0 ? $row[$_] : 0;
			$_ *= $scale;
		}

		my $rgb = sprintf("%02x%02x%02x", @rgb);
		
		my $link = "$url_cgi/3gr.display.pl?mode=right;$assign#$line_id";
		
		$blocks .= "<a href=\"$link\" target=\"right\"><span style=\"background-color:\#$rgb\"></span></a>";
	}
	
	$blocks .= "	</div>\n";
	
	#
	# put it together
	#
	
	my $title = <<END; 
	
		<h2>$target: overview</h2>
		<p>
			Each block represents one line.  Click a block to focus the full text 
			pane at right on the selected line.
		</p>
END

	
	$template =~ s/<!--title-->/$title/;
	$template =~ s/<!--navigation-->/$nav/;
	$template =~ s/<!--content-->/$blocks/;
	
	print $template;
}

sub print_right {

	my $file = catfile($fs_data, 'v3', $lang{$target}, $target, $target);
	
	my @token = @{retrieve("$file.token")};
	my @line  = @{retrieve("$file.line")};
	
	#
	# create the table with the full text of the poem
	#
	
	# first column is the locus
	# second is the color block
	# third is the text
	# fourth-sixth are the components

	my $table;

	$table .= "<table class=\"fulltext\">\n";
	
	$table .= "<tr><td></td><td></td><td></td>\n";
	
	for (@assign) {
	
		next if $_ < 0;
		
		$table .= "<td>$keys[$_]</td>\n";
	}
	
	$table .= "</tr>\n";
	
	#
	# process each line
	#
	
	for my $line_id (0..$#line) {
	
		# calculate the component brightnesses
		# and put them together to make rgb value

		my @row = @{$matrix[$line_id]};
		
		my @comp;
		
		for my $col (@assign) {
		
			my $raw  = $col >= 0 ? $row[$col] : 0;
			push @comp, sprintf("%02x", $raw * $scale);			
		}

		my $rgb = join("", @comp);

		# start the row

		$table .= "<tr>\n";
		
		# add the locus
		
		$table .= "<td><a name=\"$line_id\">$line[$line_id]{LOCUS}</a></td>\n";
			
		# now the color block
			
		$table .= "<td style=\"background-color:#$rgb; width:2em\"></td>";
		
		# now the text
		
		$table .= "<td style=\"color:#$rgb\">";
	
		for my $token_id (@{$line[$line_id]{TOKEN_ID}}) {
		
			my $display = $token[$token_id]{DISPLAY};
										
			$table .= $display;
		}
		
		$table .= "</td>\n";
		
		# now the individual components
		
		for (0..2) {
		
			my $col = $assign[$_];

			next if $col < 0;
		
			my $fg = $comp[$_] > 128 ? 'black' : 'white';			
			my $raw = sprintf("%.2f", $row[$col]);
			
			my $grey = ($comp[$_])x3;
			
			$table .= "<td style=\"background-color:#$grey; color:$fg\">$raw</td>\n";
		}

		# finish the row

		$table .= "</tr>\n";
	}

	$table .= "</table>\n";
	
	#
	# load the template
	#

	my $template = `php -f $fs_html/frame.fullscreen.php`;
		
	# title
	
	my $title = "<h2>$target: full text</h2>\n";
		
	$template =~ s/<!--title-->/$title/;
	
	# add text into template
	
	$template =~ s/<!--content-->/$table/;
	
	print $template;
}
