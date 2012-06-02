use strict;
use warnings;

# this module is used to dump data structures to binary files
# so they can be used later by other programs

use Storable qw(nstore);

# this uses an XML parsing module that doesn't come standard with the Mac OSX perl.
# you can find it a cpan.org if you want to run the program.

use XML::LibXML;
 
# initialize the parser
my $parser = new XML::LibXML;

# get the dictionary file from the first command-line argument

my $filename = shift @ARGV;;
 
# open a filehandle and parse
# these lines were adapted from the example that came with XML::LibXML

print STDERR "parsing $filename\n";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

my $doc = $parser->parse_fh( $fh );

close ($fh);

# main part of the program:
#
# get all the definitions into a hash
#

print STDERR "reading definitions\n";

# this hash will hold the definitions.
#
# each key will be a dictionary headword
# and the value will be a reference to an array containing all the 
# strings marked in the XML as being translations of the word

my %dict;

# this loop uses LibXML's methods to traverse the parsed XML document
# and look for entry nodes

for my $entry ( $doc->findnodes('//entry') )
{	
	
	# each <entry> node has a "key" attribute that gives the headword
	# in Latin.  We'll save that in the variable $key

	my $key = $entry->getAttributeNode('key')->to_literal;

	# now for this entry, look for all nodes called <tr> nested inside
	# <trans> nested inside <sense>.  This seems to be the place to
	# look for English translations of the Latin headword.
	#
	# NB this includes some strange material, due to the irregularity
	# of the dictionary. So be prepared for the unexpected at times.

	for my $trans ( $entry->findnodes('sense/trans/tr') )
	{
	
		# this gets the text of the <tr> node	

		my $string = $trans->textContent;

		# here we replace newlines with a space 

		$string =~ s/\n/ /g;

		# and delete multiple consecutive space characters

		$string =~ s/\s+/ /g;

		# the text is then added to the list of definitions
		# a reference to which is stored in the %dict hash
		# under the key $key

		push @{ $dict{$key} }, $string;
	}
}

# reuse the filename we started with, minus the .xml extension

$filename =~ s/\.xml$//;

# store the dictionary as a binary file using Storable

print STDERR "storing dictionary as $filename.cache\n"; 

nstore \%dict, "$filename.cache";

# write the plain-text version of the dictionary:

print STDERR "writing plain text to $filename.txt\n";

# first, open the output file

open FH, ">$filename.txt" || die "can't open $filename.txt for writing: $!";

# prepare the output filehandle for unicode characters; otherwise it will
# warn you every time it prints a funny char.

binmode FH, ":utf8";

# go back over all the keys of the dictionary
#
# by default 'sort' will put entries beginning with a capital 
# before the others.  To fix this, use the following instead:
#
# for ( sort { lc($a) cmp lc($b) } keys %dict )

for ( sort keys %dict )
{
	
	# print to the output file one line
	# beginning with the key, followed by a tab
	# then a semicolon-separated list of all the meanings,
	# and finally a newline

	print FH "$_\t" . join("; ", @{$dict{$_}}) . "\n";
}

# close the output file

close FH;
