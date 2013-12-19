#!/usr/bin/env perl

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}
	
	$lib = catdir($lib, 'TessPerl');	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use CGI qw(:standard);

use POSIX;
use Storable qw(nstore retrieve);

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
my $threshold = 0.5;

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

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $lang = Tesserae::lang($target);

#
# source and target data
#

if ($no_cgi) {

	print STDERR "loading $target\n" unless ($quiet);
}

my $file = catfile($fs{data}, 'v3', $lang, $target, $target);

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
				
			my $link = "$url{cgi}/lsa.pl?";

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

my $frame = `php -f $fs{html}/frame.fullscreen.php`;

# add some stuff into the head

my $head_insert = "
		<style style=\"text/css\">
			a {
				text-decoration: none;
			}
			a:hover {
				color: #888;
			}
		</style>
		<script src=\"$url{html}/tesserae.js\"></script>\n";

$frame =~ s/<!--head-->/$head_insert/;

#
# create navigation
#

# read drop down list

open (FH, "<:utf8", catfile($fs{html}, "textlist.$lang.r.php"));
my $menu;
while (<FH>) { $menu .= "$_" }
close FH;

# put together the form

my $nav = <<END_FORM;
		<form action="$url{cgi}/lsa.pl" method="POST" target="_top">
		<table class="input">
			<tr>
				<td><a href="$url{html}/experimental.php" target="_top">Back to Tesserae</a></td>
			</tr>
			<tr>
				<td>
					<input type="hidden" name="source" value="$source" />
				</td>
			</tr>
			<tr>
				<th>Source:</th>
				<td>
					<select name="target_auth" onchange="populate_work('$lang', 'target')">
					</select><br />
					<select name="target_work" onchange="populate_part('$lang', 'target')">
					</select><br />
					<select name="target">
					</select>
				</td>
			</tr>
			<tr>
				<th></th>
				<td>
					<input type="submit" value="Change" ID="btnSubmit" NAME="btnSubmit" />
				</td>
			</tr>
		</table>
		</form>
		<div style="visibility:hidden;">
			<select id="la_texts">
				$menu
			</select>
		</div>
		
		<script language="javascript">
			populate_author('$lang', 'target');
			set_defaults({'target':'$lang'}, {'target':'$target'});
		</script>

END_FORM

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
	
	my @bounds = @{retrieve(catfile($fs{data}, 'lsa', $lang, $target, 'bounds.target'))};

	return @{$bounds[$phrase_id]};
}

