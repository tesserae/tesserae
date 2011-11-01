#!/usr/bin/perl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use CGI qw/:standard/;

my $query = new CGI || die "$!";

my $session = $query->param('session');
my $sort = $query->param('sort');
my $format = $query->param('format');
my $header;
my $cmd;

if ($format eq "text") 	{
	$cmd = "xsltproc $fs_xsl/t$sort.xsl ";
        $header = "Content-type: text/plain\n\n";
}
elsif ($format eq "csv")
{
	$cmd = "xsltproc $fs_xsl/c$sort.xsl ";
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
	$cmd = "xsltproc $fs_xsl/$sort.xsl ";
        $header = "Content-type: text/html\n\n";
}

print $header;

$cmd .= "$fs_tmp/tesresults-$session.xml";

print `$cmd`;
