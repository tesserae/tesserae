#! /opt/local/bin/perl

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';
use EasyProgressBar;

print <<END;
Content-type: text/html;


<html>

	<head>
		<title>This is a test</title>
		<meta http-equiv="Refresh" content="0; url='http://ahmik/~chris/tesserae/html/index.php'">
		<style type="text/css">
			table.pr_bar {
			
				width:400px;
				border:1px solid black;
				padding:1px;
				margin:1px;
				border-collapse:collapse;
			}
			td.pr_unit {
			
				width:10px;
				padding:0px;
				margin:1px;
				color:green;
				background-color:green;				
			}
			td.pr_spacer {

				width:10px;
				height:0px;
				padding:0px;
				margin:0px;
			}
			
		</style>
	</head>
	
	<body>
		<h2>A test of the HTMLProgress package</h2>
		<p>
			Watch below...
		</p>
END

my $bar = HTMLProgress->new(10);

for (0..9) {

	$bar->advance();
	
	sleep 1;
}


print <<END;

		<p>
			You should now be redirected...
		</p>
	</body>
</html>
END

