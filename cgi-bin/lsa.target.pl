#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

use strict;
use warnings;

use CGI qw(:standard);

use Getopt::Long;
use POSIX;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

# allow unicode output

binmode STDOUT, ":utf8";

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# command-line options
#

# print debugging messages to stderr?

my $quiet = 0;

# determine file from session id

my $target    = 'lucan.bellum_civile.part.1';
my $source    = 'vergil.aeneid.part.1';
my $unit_id   = 0;
my $topics    = 15;
my $threshold = 0.7;

#
# command-line arguments
#

GetOptions( 
	'target=s'    => \$target,
	'source=s'    => \$source,
	'unit_id=i'   => \$unit_id,
	'topics|n=i'  => \$topics,
	'threshold=f' => \$threshold,
	'quiet'       => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
	
	print header(%h);

	$target = $query->param('target')   || $target;
	$source = $query->param('source')   || $source;
	$unit_id = defined $query->param('unit_id') ? $query->param('unit_id') : $unit_id;
	$topics  = $query->param('topics')  || $topics;
	$threshold = defined $query->param('threshold') ? $query->param('threshold') : $threshold; 

	$quiet = 1;
}

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = "$fs_data/common/abbr";
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = "$fs_data/common/lang";
my %lang = %{retrieve($file_lang)};

#
# source and target data
#

if ($no_cgi) {

	print STDERR "loading $target\n" unless ($quiet);
}

my $file = catfile($fs_data, 'v3', $lang{$target}, $target, $target);

my @token = @{retrieve("$file.token")};
my @line  = @{retrieve("$file.line") };	

#
# highlighted phrase
#

my ($lbound, $rbound) = getBounds($unit_id);

#
# display the full text
# 

# create the table with the full text of the poem

my $table;

$table .= "<table class=\"fulltext\">\n";

for my $line_id (0..$#line) {

	$table .= "<tr>\n";
	$table .= "<td>$line[$line_id]{LOCUS}</td>\n";
	$table .= "<td>";
	
	for my $token_id (@{$line[$line_id]{TOKEN_ID}}) {
				
		if ($token[$token_id]{TYPE} eq 'WORD') {
				
			my $link = "$url_cgi/lsa.pl?";

			$link .= "target=$target;";
			$link .= "source=$source;";
			$link .= "unit_id=$token[$token_id]{PHRASE_ID};";
			$link .= "topics=$topics;";
			$link .= "threshold=$threshold";
			
			my $marked = "";
			
			if ($token_id >= $lbound && $token_id <= $rbound) {
			
				$marked = "style=\"color:red\"";
			}
			
			$table .= "<a href=\"$link\" $marked target=\"_top\">";
		}
		
		$table .= $token[$token_id]{DISPLAY};

		$table .= "</a>" if $token[$token_id]{TYPE} eq "WORD";
	}
	
	$table .= "</td>\n";
	$table .= "</tr>\n";
}

$table .= "</table>\n";

# load the template

my $frame = `php -f $fs_html/frame.fullscreen.php`;

# add some style into the head

my $style = "
		<style style=\"text/css\">
			a {
				text-decoration: none;
			}
			a:hover {
				color: #888;
			}
		</style>\n";

$frame =~ s/<!--head-->/$style/;

#
# create navigation
#

# read drop down list

open (FH, "<:utf8", catfile($fs_html, "textlist.$lang{$target}.r.php"));
my $menu;
while (<FH>) { $menu .= "$_" }
close FH;

# mark the current text as selected

$menu =~ s/ selected=\"selected\"//g;
$menu =~ s/value="$target"/value="$target" selected="selected"/;

# put together the form

my $nav = "
		<form action=\"$url_cgi/lsa.pl\" method=\"POST\" target=\"_top\">
		<table>
			<tr>
				<td><a href=\"$url_html/experimental.php\" target=\"_top\">Back to Tesserae</a></td>
			</tr>
			<tr>
				<td>
					<input type=\"hidden\" name=\"source\" value=\"$source\" />
				</td>
			</tr>
			<tr>
				<td>Target:</td>
				<td>
					<select name=\"target\">
						$menu
					</select>
				</td>
				<td>
					<input type=\"submit\" name=\"submit\" value=\"Change\" />
				</td>
			</tr>
		</table>
		</form>\n";

$frame =~ s/<!--navigation-->/$nav/;

# insert the table into the template

my $title = <<END;
	<h2>$target</h2>
	<p>
		Click to select a phrase (plus surrounding context).  <br />
		Matches in $source will be highlighted at right.
	</p>
END

$frame =~ s/<!--title-->/$title/;

$frame =~ s/<!--content-->/$table/;

# send to browser

print $frame;

#
# subroutines
#

sub getBounds {
	
	my $phrase_id = shift;
	
	my @bounds = @{retrieve(catfile($fs_data, 'lsa', $lang{$target}, $target, 'bounds.target'))};

	return @{$bounds[$phrase_id]};
}

