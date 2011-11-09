# the line below is designed to be modified by configure.pl

use lib '/var/www/tesserae/perl';	# PERL_PATH

#
# This parses Perseus xml texts and creates .tess files
#

use TessSystemVars;
use XML::LibXML;

# set the file name and canonical abbreviation from command_line arguments

my $file_name;
my $long_name;
my $short_name;

for (@ARGV)
{

	if   	(/--long="?(.+)"?/)  	{	$long_name 	= $1 	}
	elsif	(/--short="?(.+)"?/)	{	$short_name = $1	}
	else                         	{	$filename 	= $_	}
}

if ( !defined $filename )	{	die "no file specified" }

if ( !defined $text_key)
{
	$text_key = $filename;
	
	$text_key =~ s/.*\///;
	$text_key =~ s/\.xml$//;
	$text_key =~ s/\_(?:gk|la)$//;
}

if ( !defined $short_name )	{ $short_name = $long_name }


#
# parse the Perseus xml document using XML::LibXML
#
 
print STDERR "reading XML doc $filename\n";

# initialize the parser
my $parser = new XML::LibXML;
 
# open a filehandle and parse
open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

my $doc = $parser->parse_fh( $fh );

close ($fh);



#
# read through the parsed xml structure
#
# print each line in the .tess format
#

my $file_out = "$fs_text/$long_name.tess";

open (FH, ">", $file_out) || die "can't open $file_out for writing: $!";

print STDERR "writing file $file_out\n";

# start at the "book" level
#
# sometimes called "Book" 

for my $b ( $doc->findnodes('//div1[@type="book"] | //div1[@type="Book"]') )
{	
	
	# get the book number from the "n" attribute
	
	my $bn = $b->getAttributeNode('n')->to_literal;

	# initialize the line number at the beginning of a new book

	my $ln = 0;
	
	# now get all the child "l" (line) nodes
	
	for my $l ( $b->findnodes('l') )
	{
		
		# if there's a line number specified, use it
		
		if ( defined ( $l->getAttributeNode('n') ))
		{
			$ln = $l->getAttributeNode('n')->to_literal;
		}

		# otherwise just increment

		else
		{
			$ln++;
		}

		# if there's a paragraph break marked, print a blank line
		# -- this slightly improves readability
		
		if ( $#{($l->findnodes('milestone[@unit="para"]'))} >= 0)
		{
			print FH "\n";
		}
		
		# get the text
		
		my $text = $l->textContent;
		
		# strip weird space chars like newline or tab,
		# consecutive spaces, or initial/final spaces
		
		$text =~ s/\s+/ /g;
		$text =~ s/^ //;
		$text =~ s/ $//;
		
		# print the line
		
		print FH "<$short_name $bn.$ln>\t$text\n";
	}
}

close FH;
