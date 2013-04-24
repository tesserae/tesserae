#! /opt/local/bin/perl5.12

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

use CGI qw/:standard/;

my $query = new CGI || die "$!";

my $session = $query->param('session');
my $sort = $query->param('sort');
my $format = $query->param('format');
my $header;
my $cmd;

if ($format eq "text") 	{
	$cmd = "xsltproc $fs{xsl}/t$sort.xsl ";
        $header = "Content-type: text/plain\n\n";
}
elsif ($format eq "csv")
{
	$cmd = "xsltproc $fs{xsl}/c$sort.xsl ";
        $header = "Content-type: text/csv\n";
        $header .= "Content-disposition: attachment; filename=tesresults-$session.csv\n\n";
}
elsif ($format eq "xml")
{
	$cmd = 'cat ';
        $header = "Content-type: text/xml\n";
        $header .= "Content-disposition: attachment; filename=tesresults-$session.xml\n\n";
}
else 
{
	$cmd = "xsltproc $fs{xsl}/$sort.xsl ";
        $header = "Content-type: text/html\n\n";
}

print $header;

$cmd .= "$fs{tmp}/tesresults-$session.xml";

print `$cmd`;
