use lib '/Users/chris/Sites/tesserae/perl';

use TessSystemVars;

use Storable;
use Math::MatrixSparse;

my @stoplist;
my %count = retrieve("$fs_data/common/la.word_count");

@stoplist = grep { $count{$_} < 3 } keys %count;

%count = ();

push @stoplist, @{$top{la_word}}[5];

my %first;
my %second;

print STDERR "reading input\n";

LINE: while (<>) {

	chomp;
	
	next unless s/^<.+?>\t//;
		
	$_ = lc($_);

	for (@stoplist) {
			
		s/\b$_\b//g;
	}
	
	my @words = split /[^a-z]+/;
	
	for (0..$#words) {
		
		$l = $words[$_];
		
		$count{$l}++;
			
		if ($_ < $#words) {
			
			my $r = $words[$_+1];
					
			$first{$l}{$r}++;
			$first{$r}{$l}++;
			
			if ($_ < ($#words - 1)) {
				
				$r = $words[$_+2];
				
				$second{$l}{$r}++;
				$second{$r}{$l}++;
			}
		}
	}
}

print STDERR "normalizing\n";

my @keys = sort keys %count;

my $maxlen = 0;

for my $key (@keys) {
	
	if (length($key) > $maxlen) { $maxlen = length($key) }
	
	for (values %{$first{$key}}, values %{$second{$key}}) {

		$_ = sprintf("%.5f", $_ / $count{$key});
	}
}


print STDERR "generating matrix\n";

my $rows = scalar(@keys);
my $cols = scalar(@keys) * 2;

my $matrix = Math::MatrixSparse->new();

print STDERR "0% |" . (" " x 39) . "| 100%" . "\r" . "0% |";
my $progress;
	
for (my $i = 1; $i <= $rows; $i++) {
	
	my $l = $keys[$i-1];
	
	for (my $j = 1; $j <= $cols; $j++) {
		
		my $r = $keys[int($j / 2)];
		
		if ( defined $first{$l}{$r} ) {

			$matrix->assign($i, $j, $first{$l}{$r});
		}
		
		$j++;
		
		if ( defined $second{$l}{$r} ) {
			
			$matrix->assign($i, $j, $second{$l}{$r});		
		}
	}
		
	if ($i / $rows > $progress + .025) {
		
		print STDERR ".";
		$progress = ($i / $rows);
	}
}

print STDERR "\n";

#
#
#

my $file = shift @argv || "new_matrix";

print STDERR "writing file $file\n";

$matrix->writematrixmarket($file);
