#!/usr/bin/perl

use lib '/Users/chris/sites/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use CGI qw/:standard/;

my $query = new CGI || die "$!";

print "Content-type: text/html\n\n";

my $userid =  (getpwuid($>))[0];

print <<END;

<html>
<head>
<title>Apache User Test</title>
</head>

<body>
<p>Apache runs perl scripts as user <strong>$userid</strong></p>
</body>
</html>

END
