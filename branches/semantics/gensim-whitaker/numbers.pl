# as a benchmark test of the synonym finder,
# I'll use 100 randomly selected entries from
# Döderlein's Hand-Book of Latin Synonyms
# Trans. H. H. Arnold (1858)
# which I got off Google Books

# the idea is to pick 100 random pages;
# then I'll randomly pick an entry on 
# each page and transcribe it,
# and see how these human-assigned synonyms
# rank in the automatically generated list

open FH, ">benchmark";
print FH join("\t", "page", "entry", "headword", "synonyms");

for (1..100) {

	my $page = int(rand(234))+25;
	
	print "$_\n   Page $page. \n\tHow many entries? ";
	
	my $max = <>;
	$max = int($max);
	
	my $entry = int(rand($max))+1;
	
	print "   Entry $entry\n\tHeadword:";
	
	my $headword = <>;
	chomp $headword;
	
	print "\tSynonyms:";
	
	my $syn = <>;
	$syn = s/^\W+//;
	$syn = s/\W+$//;
	my @syn = split /\W+/, $syn;
		
	print FH join("\t", $page, $entry, $headword, "(" . join(", ", @syn) . ")") . "\n";
}

close FH;