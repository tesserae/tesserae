

for my $max_heads (50, 100, 200) {
	
	for my $min_similarity (.5, .7, .9) {

		my $file = "batch/h${max_heads}s" . sprintf("%02i", $min_similarity * 100); 
		
		`perl rydberg-cox.pl --max_heads $max_heads --min_similarity $min_similarity --hist $file.hist`;
		
	}
}