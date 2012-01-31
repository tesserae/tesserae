# claudian parser
#
# modified from the martial parser
#
# Chris Forstall
# 18-01-2012
#
# input is the perseus file containing claudian
# panegyricus dictus Probino et Olybrio consulibus
#
# output is .tess format


use strict;
use warnings;

#
# it's easier to read this file without an XML parser
#

my @book;
my @poem;

my $bn;
my $pn;
my @line;
my @ln;

my $filename = shift(@ARGV) 	|| "claudian.panegyricus_dictus_probino_et_olybrio_consulibus.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

while ( <$fh> )
{
	if (/<lb rend="displayNum" n="(.+?)" \/>(.+)\n/) {
	
		push @ln, $1;
			
		my $line = $2;

		$line =~ s/&quot;/"/g;
		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[a-z]+;//g;
		$line =~ s/\+//g;
		$line =~ s/<.+?>//g;
			
		push @line, $line;
	}
}

close ($fh);


#
# now print formatted output
#

print STDERR "writing output\n";
binmode STDOUT, ":utf8";

for (0..$#line) {
	print "<claud. cons. olyb. et prob. $ln[$_]>\t$line[$_]\n";
}