# How to use:
#    Fill in the 'score' subroutine with your algorithm.
#    Save as Yourname.pm in the 'plugins' directory
#    Remember to change XXX to Yourname in the line below.

package XXX;

use strict;
use Exporter;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

# load configuration file

my $tesslib;

BEGIN {
	
	my $dir  = $Bin;
	my $prev = "";
			
	while (-d $dir and $dir ne $prev) {

		my $pointer = catfile($dir, '.tesserae.conf');

		if (-s $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$tesslib = <FH>;
			
			chomp $tesslib;
			
			last;
		}
		
		$dir = abs_path(catdir($dir, '..'));
	}
	
	unless ($tesslib) {
	
		die "can't find .tesserae.conf!";
	}
}

# load Tesserae-specific modules

use lib $tesslib;

use Tesserae;
use EasyProgressBar;

# additional modules

use Storable;

# set some parameters

our $VERSION   = 0.01;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

#
# scoring subroutine
#

sub score {
		
	my ($package, $match, $debug) = @_;
	
	#
	# elements of the match
	#

	# an array of all the words in the target

	my @token_target = @{$match->[0]};
	
	# their frequencies in the same order
	
	my @freq_target  = @{$match->[1]};
	
	# ids of matching words, indexed to position in the above arrays
	
	my @match_target = @{$match->[2]};	

	# words in the source phrase

	my @token_source = @{$match->[3]};
	
	# frequencies of words in the source phrase
	
	my @freq_source  = @{$match->[4]};	
	
	# ids of matching words in the source phrase
	
	my @match_source = @{$match->[5]};
	
	# debugging message (optional)
	
	# print STDERR "" if $debug;
	
	#
	# calculate score
	#
	
	# your code here
	
	my $score = 0;
	
	return $score;
}

#
# distance measurement
#  - taken from read_table.pl
#  - use, modify as needed, or ignore

sub dist {

	my ($match, $metric, $debug) = @_;

	my @token_target = @{$match->[0]};
	my @freq_target  = @{$match->[1]};
	my @match_target = @{$match->[2]};	
	my @token_source = @{$match->[3]};
	my @freq_source  = @{$match->[4]};	
	my @match_source = @{$match->[5]};

	my @target_id = sort {$a <=> $b} @match_target;
	my @source_id = sort {$a <=> $b} @match_source;

	my $dist = 0;

	#
	# distance is calculated by one of the following metrics
	#

	# freq: count all words between (and including) the two lowest-frequency 
	# matching words in each phrase.  NB this is the best metric in my opinion.

	if ($metric eq "freq") {
		
		# sort target token ids by frequency of the forms
		
		my @t = sort {$freq_target[$a] <=> $freq_target[$b]} @target_id;
				
		# now count distance between them
		
		$dist += abs($t[0] - $t[1]) + 1;
				
		# now do the same in the source phrase

		my @s = sort {$freq_source[$a] <=> $freq_source[$b]} @source_id;

		$dist += abs($s[0] - $s[1]) + 1;
	}

	# freq_target: as above, but only in the target phrase

	elsif ($metric eq "freq_target") {

		# sort target token ids by frequency of the forms

		my @t = sort {$freq_target[$a] <=> $freq_target[$b]} @target_id; 

		# now count distance between them

		$dist += abs($t[0] - $t[1]) + 1;
	}

	# freq_source: ditto, but source phrase only

	elsif ($metric eq "freq_source") {

		my @s = sort {$freq_source[$a] <=> $freq_source[$b]} @source_id;

		$dist += abs($s[0] - $s[1]) + 1;
	}

	# span: count all words between (and including) first and last matching words

	elsif ($metric eq "span") {

		# check all tokens from the first (lowest-id) matching word
		# to the last.  increment distance only if token is of type WORD.

		$dist += abs($target_id[0] - $target_id[-1]) + 1;
		$dist += abs($source_id[0] - $source_id[-1]) + 1;
	}

	# span_target: as above, but in the target only

	elsif ($metric eq "span_target") {

		$dist += abs($target_id[0] - $target_id[-1]) + 1;
	}

	# span_source: ditto, but source only

	elsif ($metric eq "span_source") {

		$dist += abs($source_id[0] - $source_id[-1]) + 1;
	}

	return $dist;
}

1;