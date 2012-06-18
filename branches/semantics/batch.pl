

for my $max_heads (50, 100, 200) {
	
	for my $min_similarity (.5, .7, .9) {
		

		my $file = "batch/h${max_heads}s" . sprintf("%02i", $min_similarity * 100); 
		
		`perl rydberg-cox.pl --max_heads $max_heads --min_similarity $min_similarity --hist $file.hist --cache`;
		
		`perl ~/Sites/tesserae/perl/v3/synonyms_add_column.pl ~/Sites/tesserae/texts/la/vergil.aeneid.tess`;
		`perl ~/Sites/tesserae/perl/v3/synonyms_add_column.pl ~/Sites/tesserae/texts/la/lucan.pharsalia/lucan.pharsalia.part.1.tess`;
		`perl ~/Sites/tesserae/cgi-bin/read_table.pl --no-cgi --source vergil.aeneid --target lucan.pharsalia.part.1 --feature syn > $file.tesresults`;
	}
}