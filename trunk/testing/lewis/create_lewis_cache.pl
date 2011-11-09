use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# crate_lewis_cache.pl
#
# a program to read the big lewis and short from perseus
# and create a hash of english definitions for all the 
# latin headwords in the tesserae corpus, following the
# example of roelant's stem.cache


use strict;
use warnings;

use TessSystemVars;

# uses XML::LibXML, which didn't come standard on my Mac

use XML::LibXML;
use Data::Dumper;
use Storable qw(nstore);

# the bit below was copied from the XML::LibXML example

# initialize the parser

my $parser = new XML::LibXML;

my $filename = shift @ARGV || 'lewis-short.xml';

my $file_out = shift @ARGV || "$fs_data/common/la.semantic.cache";

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

my %lewis;

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

	# strip diacritic markers

	$key =~ s/[^a-z ]//ig;

	# entries have multiple <sense>s

	for my $sense ( $entry->findnodes('sense') )
	{

		# english definitions are marked by italics

		for my $ital ( $sense->findnodes('hi[@rend="ital"]') )
		{

			my $def = $ital->textContent;

			push @{$lewis{$key}}, $def;

			$def_counter++;
		}
	}
}

print STDERR "lowercasing keys\n";

for (grep { /[A-Z]/ } keys %lewis)
{
	
	my $this = $_;
	my $base = lc($_);
	
	if ( defined $lewis{$base} )
	{
		my %unique;
		
		for (@{$lewis{$this}}, @{$lewis{$base}})
		{
			next if ($_ eq "");
			
			$unique{$_} = 1;
		}
		
		$lewis{$base} = [keys %unique];
	}
	else
	{
		$lewis{$base} = $lewis{$this};
	}
	delete $lewis{$this};
}

print STDERR "\n";

print STDERR scalar(keys %lewis) . " keys, $def_counter definitions extracted\n\n";

print STDERR "writing $file_out\n";

nstore \%lewis, $file_out;
