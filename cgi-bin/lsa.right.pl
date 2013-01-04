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
use LWP::UserAgent;

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
my $tphrase = 0;
my $vbook  = 1;
my $threshold = .7;
my $ntopics = 15;

#
# command-line arguments
#

GetOptions( 
	'vbook=i'     => \$vbook,
	'tphrase=i'   => \$tphrase,
	'threshold=i' => \$threshold,
	'quiet'       => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
	
	print header(%h);

	$vbook     = $query->param('vbook')     || $vbook;
	$tphrase   = $query->param('tphrase')   || $tphrase;
	$threshold = $query->param('threshold');
	$quiet = 1;
}

#
# get LSA results from Walter's script
#

print STDERR "querying LSA tool\n" unless $quiet;

my %lsa = %{getLSA($tphrase, $ntopics, $vbook, $threshold)};

print STDERR "lsa returned " . scalar(keys %lsa) . " phrases above threshold $threshold\n" unless $quiet;

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

	print STDERR "loading $source\n" unless ($quiet);
}

my $file = catfile($fs_data, 'v3', $lang{$source}, $source, $source);

my @token = @{retrieve("$file.token")};
my @line  = @{retrieve("$file.line")};	


#
# display the full text
# 

# create the table with the full text of the poem

my $table;

$table .= "<table class=\"fulltext\">\n";

for my $line_id (0..$#line) {

	next unless $line[$line_id]{LOCUS} =~ /$vbook\.\d+/;

	$table .= "<tr>\n";
	$table .= "<td>$line[$line_id]{LOCUS}</td>\n";
	$table .= "<td>";
	
	for my $token_id (@{$line[$line_id]{TOKEN_ID}}) {
	
		my $display = $token[$token_id]{DISPLAY};
		
		if (defined $token[$token_id]{PHRASE_ID} && 
			defined $lsa{$token[$token_id]{PHRASE_ID}}) {
			
			my $color = $lsa{$token[$token_id]{PHRASE_ID}} * 256;
			
			$color = "#" . sprintf("%02x%02x00", $color, $color);
			
			$display = "<span style=\"color:$color\">" . $display . "</span>";
		}
		
		$table .= $display;
	}
	
	$table .= "</td>\n";
	$table .= "</tr>\n";
}

$table .= "</table>\n";

# load the template

my $frame = `php -f $fs_html/lsa.right.php`;

# insert the table into the template

$frame =~ s/<!--me-->/Vergil Aeneid Book $vbook/g;
$frame =~ s/<!--other-->/$target/g;

$frame =~ s/<!--fulltext-->/$table/;

# send to browser

print $frame . "\n";


#
# subroutines
#

sub getLSA {

	my ($tphrase, $ntopics, $vbook, $threshold) = @_;
	
	my $browser  = LWP::UserAgent->new;
	my $response = $browser->post(
		'http://tesserae.vast.uccs.edu/cgi-bin/lsa_tool.py',
		[
			'query_id'    => sprintf("%03i", $tphrase),
			'num_topics' => $ntopics,
			'dropdown' => 'vergil_aeneid_book' . sprintf("%02i", $vbook),
			'submit' => 'SUBMIT'
		],
	);

	my $results = $response->content;

	my %lsa;

	while ($results =~ s/(.+?)\n//) {
	
		my $line = $1;
		
		next unless $line =~ /\d+\s+(\d+)\s+\d\.\d+\s.+(0\.\d+)/;
		
		my ($sphrase, $score) = ($1, $2);
		
		next unless $score >= $threshold;
		
		$lsa{$sphrase} = $score;
	}

	return \%lsa;
}
