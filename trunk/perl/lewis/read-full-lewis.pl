#
# crate_lewis_cache.pl
#
# a program to read the big lewis and short from perseus
# and create a hash of english definitions for all the 
# latin headwords in the tesserae corpus, following the
# example of roelant's stem.cache

use lib '/Users/chris/Desktop/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

# uses XML::LibXML, which didn't come standard on my Mac

use XML::LibXML;
use Storable qw(nstore retrieve);

use TessSystemVars;

# the bit below was copied from the XML::LibXML example

# initialize the parser

my $parser = new XML::LibXML;

my $filename = shift @ARGV || "$fs_data/common/lewis-short.xml";

print STDERR "parsing $filename\n";

# open a filehandle and parse

open (my $fh, "<", $filename)   || die "can't open $filename: $!";

my $doc = $parser->parse_fh( $fh );

close ($fh);

#
# pull all the entry nodes, called entryFree in the full lewis & short
#

my @entry = $doc->findnodes( '//entryFree' );

print STDERR scalar(@entry) . " entries\n\n";

#
# check each entry for its headword, and definitions in italics
#

print STDERR "reading definitions\n";

# this hash will hold the definitions; keys will be the headwords

my %def;
my %text;

# this is just to count definitions in passing

my $def_counter;

# draw a progress bar

print STDERR "0% |" . (" "x40) . "| 100%\r0% |";

my $counter = 0;
my $progress = 0;

# loop over all the entries

for my $entry (@entry)
{

	# advance the progress bar

	$counter++;

	if ( ($counter/$#entry) > $progress + .025)
	{
		print STDERR ".";

		$progress += .025;
	}

	# get the headword for this entry

	my $key = $entry->getAttributeNode('key')->to_literal;
	
	$key = lc($key);
	$key =~ s/[^a-z]//g;
	$key =~ tr/j/i/;

	# get definitions

	for my $ital ( $entry->findnodes('sense/hi[@rend="ital"]') )
	{
		push @{$def{$key}}, $ital->textContent;
	}

	my $long_string = $entry->textContent;

	$text{$key} .= $long_string. " ";

}

print STDERR "\n";

# clear the object-oriented stuff from memory

@entry = ();

# save results

my $file_cache = shift @ARGV || "$fs_data/common/la.semantic.cache";
print "saving $file_cache\n";
nstore \%def, $file_cache;

my $file_text = shift @ARGV || "$fs_data/common/lewis.text.cache";
print "saving $file_text\n";
nstore \%text, $file_text;

print "\n";

