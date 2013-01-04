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
# options
#

# print debugging messages to stderr?

my $quiet = 0;

# determine file from session id

my $target = 'lucan.bellum_civile.part.1';
my $source = 'vergil.aeneid';
my $vbook  = 1;
my $tphrase = 0;
my $threshold = .7;

#
# command-line input
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
# create the frameset and redirect to content
# 

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
		<frame name="left"  src="$url_cgi/lsa.left.pl?tphrase=$tphrase;vbook=$vbook;threshold=$threshold">
		<frame name="right" src="$url_cgi/lsa.right.pl?tphrase=$tphrase;vbook=$vbook;threshold=$threshold">
	</frameset>
</html>

END
