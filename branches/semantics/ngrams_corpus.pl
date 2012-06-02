use lib '/Users/chris/Sites/tesserae/perl';

use TessSystemVars;

use Storable;

# the stoplist is the top most frequent words
# plus any words that don't occur more than
# twice in the entire corpus

my @stoplist;
my %count = retrieve("$fs_data/common/la.word_count");

@stoplist = grep { $count{$_} < 3 } keys %count;

push @stoplist, @{$top{la_word}}[20];

# the context size in words

my $n = 5;

# read one phrase at a time

print STDERR "reading input\n";

# this holds the working phrase

my $working;

LINE: while (<>) {

	chomp;
	
	next unless s/^<.+?>\t//;
		
	$_ = lc($_);

	for (@stoplist) {
			
		s/\b$_\b//g;
	}
	
	# if we haven't reached the end of the
	# phrase, just keep going
	
	unless (/[.;!?]/) {
		
		$working .= " " . $_;
		next;
	}
	
	# if at least one phrase ends on this
	# line, start processing
	
	my @part = split /[.;!?]+/;
	
	# add the carryover to the first part
	
	$part[0] = $working . " " . $part[0];
	
	for (@part[0..$#part-1]) {
		
		ngramize($_, $n);
	}
	
	$working = $part[-1];
}

ngramize($working, $n);


sub tokenize {
	
	my $string = shift;
		
	my @words = grep { $_ ne "" } (split /[^a-z]+/, $string); 

	return @words;
}

sub ngramize {

	my ($string, $n) = @_;
	
	my @tokens = tokenize($string);
	
	my @ngrams;
	
	if (scalar(@tokens) < $n) { 
		
		$ngrams[0] = join(" ", @tokens);
	}
	else {
	
		for (0..scalar(@ngrams)-$n) {
			
			push @ngrams, join(" ", @ngrams[$_..$_+$n])
		}
	}
}