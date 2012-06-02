binmode STDOUT, ":utf8";

# this uses an XML parsing module that doesn't come standard with the Mac OSX perl.
# you can find it a cpan.org if you want to run the program.

use XML::LibXML;
 
# initialize the parser
my $parser = new XML::LibXML;

my $filename = shift @ARGV;;
 
# open a filehandle and parse
print STDERR "parsing $filename\n";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

my $doc = $parser->parse_fh( $fh );

close ($fh);

# get all the definitions into a hash

print STDERR "reading definitions\n";

my %dict;
my %engl_count;
my @ordered_keys;

for my $entry ( $doc->findnodes('//entry') )
{	
	my $key = $entry->getAttributeNode('key')->to_literal;

	push @ordered_keys, $key;	

	for my $trans ( $entry->findnodes('sense/trans/tr') )
	{
		my $string = $trans->to_literal;
		push @{$dict{$key}}, $string;

		my @words = (split /\W+/, $string);

		for (@words)
		{
			next unless ( /[aeiouy]/i );
			$engl_count{lc($_)}++;
		}
	}
}

# write output

print STDERR "writing counts\n";

print scalar( keys %engl_count ) . " unique English words\n";

for ( sort {$engl_count{$b} <=> $engl_count{$a} } keys %engl_count)
{
	print "$engl_count{$_}\t$_\n";
}

