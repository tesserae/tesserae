use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';
use TessSystemVars;

open (FH, "<", "$fs_data/common/DICTPAGE.RAW");

my @rec;
my %alphabet;

while (<FH>) {

	if (/#(.+?)  (.+)\s+(\[.....\]) :: (.+)\n/) {
		
		push @rec, {
			
			HEAD 	=> $1,
			POS	=> $2,
			CODE	=> $3,
			BODY	=> $4
		};
		
		push @{$alphabet{lc(substr($1, 0, 1))}}, $#rec;
	}
}

close FH;

for my $l (sort keys %alphabet) {

	open (FH, ">", "/Users/chris/Sites/whitaker/$l.html");
	
	print FH "<html>\n";
	print FH "<head>\n";
	print FH "	<title>$l</title>\n";
	print FH "</head>\n";
	print FH "\n";
	print FH "<body>\n";

	print FH "   <div class=\"index\">\n";

	for my $l_ (sort keys %alphabet) {
		
		if ($l_ ne $l) {
			
			print FH "<a href=\"http://localhost/~chris/whitaker/$l_.html\">$l_</a>";
		}
		else {
			
			print FH $l_;
		}
		
		print FH "\n";
	}
	
	print FH "   </div>\n";
	print FH "\n";
	print FH "   <table>\n";
	
	for my $i (@{$alphabet{$l}}) {
	
		print FH "      <tr>\n";
		print FH "         <td>";
		print FH "<a href=\"http://localhost/~chris/whitaker/cgi-bin/whitaker.test.py?lineno=$i\">";
		print FH $rec[$i]{HEAD};
		print FH "</a></td>\n";
		
		print FH "         <td>" . $rec[$i]{POS}  . "</td>\n";
		print FH "         <td>" . $rec[$i]{BODY} . "</td>\n";
		print FH "      </tr>\n";
		
	}
	
	print FH "   </table>\n";
	print FH "</body>\n";
	print FH "</html>\n";
	
	close FH;
}