# claudian parser
#
# modified from the martial parser
#
# Chris Forstall
# 18-01-2012
# rev. 02-07-2012
#
# output is .tess format


use strict;
use warnings;

use Getopt::Long;

# usage

my $usage =<<END;

usage: 

   perl claudian-tess.pl [--div A:B:C...] [--tag STRING] FILE

   where
		A, B, C, ... = names of major division types in XML (as in <div* type="A">)
							NB. 'line' will be added as the rightmost element
							if it isn't specified anywhere else.
      STRING       = human-readable abbreviation to precede line numbers
      FILE         = XML file to parse
END

#
# it's easier to read this file without an XML parser
#

my @book;
my @poem;

my $bn;
my $pn;
my @line;
my @ln;

# get command-line options

my $tag = 'default';
my $struct = '';
my $help = 0;

GetOptions('tag=s' => \$tag, 'div=s' => \$struct, 'help' => \$help); 

# set up the structure

my @order = split(":", lc($struct));
my %num;

unless (grep {/line/} @order) { push @order, 'line' }

# read arguments

my $filename = shift(@ARGV);

if ($help eq 1 || not defined $filename) {
	print $usage;
	exit;
}


#
# parse the input file
#

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "parsing $filename\n";

while ( <$fh> )
{
	# check for division numbers
	
	if (/<div.\b.*? type="(.+?)"/) {
	
		my $div = $1;
	
		$num{$div} = /n="(.+?)"/ ? $1 : "";	
	}
	
	# check for lines of verse
	
	if (/<lb rend="displayNum" n="(.+?)" \/>(.+)\n/) {
	
		# set the line number;
	
		$num{line} = $1;
			
		my $line = $2;

		$line =~ s/&quot;/"/g;
		$line =~ s/<\/?q\b.*?>/"/g;
		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[a-z]+;//g;
		$line =~ s/\+//g;
		$line =~ s/<.+?>//g;
			
		my @locus;
		
		for (@order) { push @locus, $num{$_} }
		
		print "<$tag " . join(".", @locus) . ">\t$line\n";
	}
}

close ($fh);
