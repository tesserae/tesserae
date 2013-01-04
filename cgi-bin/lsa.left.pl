#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/var/www/tesserae/perl';	# PERL_PATH

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

my $target = 'lucan.bellum_civile.part.1';
my $source = 'vergil.aeneid';
my $vbook  = 1;
my $tphrase = 0;
my $threshold = 0.7;

#
# command-line arguments
#

GetOptions( 
	'tphrase=i' => \$tphrase,
	'vbook=i'   => \$vbook,
	'threshold=f' => \$threshold,
	'quiet'     => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
	
	print header(%h);

	$tphrase = $query->param('tphrase')   || $tphrase;
	$vbook   = $query->param('vbook')     || $vbook;
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

my ($lbound, $rbound) = getBounds($tphrase);

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
			
			$link .= "tphrase=$token[$token_id]{PHRASE_ID};";
			$link .= "vbook=$vbook;";
			$link .= "threshold=$threshold";
			
			my $marked = "";
			
			if ($token_id >= $lbound && $token_id <= $rbound) {
			
				$marked = "style=\"color:#aa5555\"";
			}
			
			if ($token[$token_id]{PHRASE_ID} == $tphrase) {
			
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

my $frame = `php -f $fs_html/lsa.left.php`;

# insert the table into the template

$frame =~ s/<!--me-->/$target/g;
$frame =~ s/<!--other-->/Vergil Aeneid Book $vbook/g;

$frame =~ s/<!--fulltext-->/$table/;

# send to browser

print $frame;

#
# subroutines
#

sub getBounds {
	
	my $phrase_id = shift;
	
	my @bounds = @{retrieve(catfile($fs_data, 'lsa', 'bounds.target'))};

	return @{$bounds[$phrase_id]};
}

