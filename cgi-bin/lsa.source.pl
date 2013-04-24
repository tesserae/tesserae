#! /opt/local/bin/perl5.12

#
#
#

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
use LWP::UserAgent;

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

my $target = 'lucan.bellum_civile.part.1';
my $source = 'vergil.aeneid.part.1';
my $unit_id = 0;
my $threshold = .7;
my $topics = 15;

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

	$target    = $query->param('target')   || $target;
	$source    = $query->param('source')   || $source;
	$unit_id   = defined $query->param('unit_id') ? $query->param('unit_id') : $unit_id;
	$topics    = $query->param('topics')   || $topics;
	$threshold = defined $query->param('threshold') ? $query->param('threshold') : $threshold; 

	$quiet = 1;
}

#
# get LSA results from Walter's script
#

print STDERR "querying LSA tool\n" unless $quiet;

my %lsa = %{getLSA($target, $source, $unit_id, $topics, $threshold)};

print STDERR "lsa returned " . scalar(keys %lsa) . " phrases above threshold $threshold\n" unless $quiet;

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

#
# source and target data
#

if ($no_cgi) {

	print STDERR "loading $source\n" unless ($quiet);
}

my $file = catfile($fs{data}, 'v3', $lang{$source}, $source, $source);

my @token = @{retrieve("$file.token")};
my @line  = @{retrieve("$file.line")};	


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
	
		my $display = $token[$token_id]{DISPLAY};
		
		if (defined $token[$token_id]{PHRASE_ID} && 
			defined $lsa{$token[$token_id]{PHRASE_ID}}) {
			
			my $score = sprintf("%.2f", $lsa{$token[$token_id]{PHRASE_ID}});
			
			my $color = $score * 256;
			
			$color = "#" . sprintf("%02x0000", $color, $color);
			
			$display = "<span style=\"color:$color\" title=\"$score\">" . $display . "</span>";
		}
		
		$table .= $display;
	}
	
	$table .= "</td>\n";
	$table .= "</tr>\n";
}

$table .= "</table>\n";

# load the template

my $file_frame = catfile($fs{html}, 'frame.fullscreen.php');
my $frame = `php -f $file_frame`;

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

open (FH, "<:utf8", catfile($fs{html}, "textlist.$lang{$source}.r.php"));
my $menu_source;

while (<FH>) { 

	$menu_source .= "$_";
}

close FH;

# mark the current text as selected

$menu_source =~ s/ selected=\"selected\"//g;
$menu_source =~ s/value="$source"/value="$source" selected="selected"/;

# topics menu

my $menu_topics;

for (my $n = 5; $n <= 50; $n += 5) {

	my $selected = ($n == $topics ? ' selected="selected"' : '');
	
	$menu_topics .= "<option value=\"$n\"$selected>$n</option>\n";
}

# put together the form

my $nav = "
		<form action=\"$url{cgi}/lsa.pl\" method=\"POST\" target=\"_top\">
		<table>
			<tr>
				<td><a href=\"$url{html}/experimental.php\" target=\"_top\">Back to Tesserae</a></td>
			</tr>
			<tr>
				<td>
					<input type=\"hidden\" name=\"target\" value=\"$target\" />
				</td>
			</tr>
			<tr>
				<td style=\"text-align:left\">Source:</td>
				<td>
					<select name=\"source\">
						$menu_source
					</select>
				</td>
				<td>
					<input type=\"submit\" name=\"submit\" value=\"Change\" />
				</td>
			</tr>
			<tr>
				<td style=\"text-align:left\">Number of Topics:</td>
				<td style=\"text-align:left\">
					<select name=\"topics\">
						$menu_topics
					</select>
				</td>
			</tr>
		</table>
		</form>\n";

$frame =~ s/<!--navigation-->/$nav/;

# insert the table into the template

my $title = <<END;
	<h2>$source</h2>
END

$frame =~ s/<!--title-->/$title/;

$frame =~ s/<!--content-->/$table/;

# send to browser

print $frame . "\n";


#
# subroutines
#

sub getLSA {

	my ($target, $source, $unit_id, $topics, $threshold) = @_;
	
	my $browser  = LWP::UserAgent->new;
	my $response = $browser->post(
		"$url{cgi}/lsa.search.py",
		[
			'target'  => $target,
			'source'  => $source,
			'unit_id' => $unit_id,
			'topics'  => $topics,
			'submit'  => 'SUBMIT'
		],
	);

	my $results = $response->content;

	my %lsa;

	while ($results =~ s/(.+?)\n//) {
	
		my $line = $1;
				
		my ($sphrase, $score) = split(/\s+/, $line);
				
		next unless $score >= $threshold;
		
		$lsa{$sphrase} = $score;
	}

	return \%lsa;
}
