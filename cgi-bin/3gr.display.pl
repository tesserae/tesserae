#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

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

my $scale = 20;

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

print $session->header(-encoding=>"utf8");

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

my $mode = $session->param("mode") || 'left';

# print page top

print_top();

# print content according to mode (left/right)

if ($mode eq 'left') {

	print_left();

}
elsif ($mode eq 'right') {

}

# finish the page

print_bottom();

#
# subroutines
#

sub print_top {

	print <<END;
	
<html>
	<head>
		<title>$target</title>
		<style type="text/css">
			div.colour_blocks
			{
				color:white;
				background-color:black;
			}
			div.colour_blocks span
			{
				float:left;
				padding-left:10px;
				height:15px;
			}
		</style>
	</head>
	<body>
END

}

sub print_bottom {

	print <<END;
	
	</body>
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

	print <<END;
	
	<div>
		<h2>$target</h2>

		<form action=$url_cgi/3gr.display.pl method=POST>
			<table>
				<tr><th>red  </th><td>$red  </td><td>$menu_r</td><td></td></tr>
				<tr><th>green</th><td>$green</td><td>$menu_g</td><td><input type="submit" value="Change"></td></tr>
				<tr><th>blue </th><td>$blue </td><td>$menu_b</td><td></td></tr>
			</table>
		</form>
	</div>
	
	<div class="colour_blocks">
				
END

	for my $row (@matrix) {
	
		my @row = @$row;
		
		my @rgb = @assign;
		
		for (@rgb) {
		
			$_ = $_ >= 0 ? $row[$_] : 0;
			$_ *= $scale;
		}

		my $rgb = sprintf("%02x%02x%02x", @rgb);
		
		print "<span style=\"background-color:\#$rgb\"> </span>";
	}
	
	print "	</div>\n";
}

sub print_right {

	my $file = catfile($fs_data, 'v3', $lang{$target}, $target, $target);
	
	my @token = @{retrieve("$file.token")};
	my @unit  = @{retrieve("$file.$unit")};
	
}
