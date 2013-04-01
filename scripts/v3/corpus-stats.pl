#
# corpus-stats.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use File::Spec::Functions;
use Storable qw(nstore retrieve);

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV) {

	if (/^[a-zA-Z]{1,4}$/)	{ 
	
		next unless -d catdir($fs_data, 'v3', $_);
		push @lang, $_;
	}
}

#
# main loop
#

# word counts come from documents already parsed.
# stem counts are based on word counts, but also 
# use the cached stem dictionary
#

for my $lang(@lang) {
	
	# get a list of all the word counts

	my @texts;
	
	my $dir = catdir($fs_data, 'v3', $lang);

	opendir (DH, $dir);

	push @texts, (grep {!/\.part\./ && !/^\./} readdir DH);

	closedir (DH);

	#
	# combine the counts for each file to get a corpus count
	#

	my %total;
	my %count;

	for my $text (@texts) {
	
		print STDERR "checking $text:";
		
		for my $feature (qw/word stem syn 3gr/) {
		
			my $file_index = catfile($fs_data, 'v3', $lang, $text, "$text.index_$feature");

			next unless -s $file_index;

			my %index = %{retrieve($file_index)};

			print STDERR " $feature";

			for (keys %index) { 
			
				$count{$feature}{$_} += scalar(@{$index{$_}});
				$total{$feature}     += scalar(@{$index{$_}});
			}
		}
		
		print STDERR "\n";
	}

	# after the whole corpus is tallied,	
	# convert counts to frequencies and save
	
	for my $feature (qw/word stem syn 3gr/) {
	
		next unless defined $count{$feature};

		my $file_freq = catfile($fs_data, 'common', $lang . '.' . $feature . '.freq');

		print STDERR "writing $file_freq\n";

		open (FREQ, ">:utf8", $file_freq) or die "can't write $file_freq: $!";

		print FREQ "# count: $total{$feature}\n";
		
		for (sort {$count{$feature}{$b} <=> $count{$feature}{$a}} keys %{$count{$feature}}) {
		
			print FREQ "$_\t$count{$feature}{$_}\n";
		}

		close FREQ;
	}
}