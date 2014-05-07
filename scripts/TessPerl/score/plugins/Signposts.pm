package Signposts;

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

	$tesslib = catdir($tesslib, 'TessPerl');	
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

# diagnostic

print STDERR "loading module Signpost\n";

#
# scoring subroutine
#

sub score {
		
	my ($package, $match, $phrases, $debug) = @_;
	
	my @token_target = @{$match->[0]};
	my @freq_target  = @{$match->[1]};
	my @match_target = @{$match->[2]};
	my $mark_target  = $match->[3];
	my @token_source = @{$match->[4]};
	my @freq_source  = @{$match->[5]};	
	my @match_source = @{$match->[6]};
	my @phrase = @{$phrases};

	if ($debug) { print STDERR "\n" }
	
	my $distance = dist($match, 'freq', $debug);
	
	my $score = 0;
		
	for my $token_id_target (@match_target ) {
									
		# add the frequency score for this term
		
		$score += 1/$freq_target[$token_id_target];
		
		if ($debug) {
			print STDERR "score: ";
			print STDERR "token=$token_target[$token_id_target];";
			print STDERR "freq=$freq_target[$token_id_target];";
			print STDERR "finv=" . sprintf("%.2f", 1/$freq_target[$token_id_target]).";";
			print STDERR "score=" . sprintf("%.2f", $score) . "\n";
		}
	}
	
	for my $token_id_source ( @match_source ) {

		# add the frequency score for this term
		
		$score += 1/$freq_source[$token_id_source];
		
		if ($debug) {
			print STDERR "score: ";
			print STDERR "token=$token_source[$token_id_source];";
			print STDERR "freq=$freq_source[$token_id_source];";
			print STDERR "finv=" . sprintf("%.2f", 1/$freq_source[$token_id_source]).";";
			print STDERR "score=" . sprintf("%.2f", $score) . "\n";
		}
	}
		
	if ($debug) {
	
		print STDERR "score: score/distance=" . sprintf("%.2f", $score/$distance). "\n";
		print STDERR "score: log(score/distance)=" . sprintf("%.2f", log($score/$distance)). "\n";
	}

	$score = sprintf("%.3f", log($score/$distance));

	$score = ($mark_target + $score);
#	if ($mark_target > 0){ print STDERR "\n$mark_target"};


	return $score;
}

#
# distance measurement
#

sub dist {

	my ($match, $metric, $debug) = @_;

	my @token_target = @{$match->[0]};
	my @freq_target  = @{$match->[1]};
	my @match_target = @{$match->[2]};
	my $mark_target  = $match->[3];
	my @token_source = @{$match->[4]};
	my @freq_source  = @{$match->[5]};	
	my @match_source = @{$match->[6]};
	my @target_id = sort {$a <=> $b} @match_target;
	my @source_id = sort {$a <=> $b} @match_source;

	my $dist = 0;

	if ($debug) {
	
		print STDERR "dist: metric=$metric\n";
	}

	#
	# distance is calculated by one of the following metrics
	#

	# freq: count all words between (and including) the two lowest-frequency 
	# matching words in each phrase.  NB this is the best metric in my opinion.

	if ($metric eq "freq") {
		
		# sort target token ids by frequency of the forms
		
		my @t = sort {$freq_target[$a] <=> $freq_target[$b]} @target_id;
		
		if ($debug) {
		
			print STDERR "dist: t[0]=$t[0]\t$token_target[$t[0]]\t$freq_target[$t[0]]\n";
			print STDERR "dist: t[1]=$t[1]\t$token_target[$t[1]]\t$freq_target[$t[1]]\n";
		}
		
		# now count distance between them
		
		$dist += abs($t[0] - $t[1]) + 1;
		
		if ($debug) {
		
			print STDERR "dist: dist=$dist\n";
		}
		
		# now do the same in the source phrase

		my @s = sort {$freq_source[$a] <=> $freq_source[$b]} @source_id;

		if ($debug) {
		
			print STDERR "dist: s[0]=$s[0]\t$token_source[$s[0]]\t$freq_source[$t[0]]\n";
			print STDERR "dist: s[1]=$s[1]\t$token_source[$s[1]]\t$freq_source[$t[1]]\n";
		}

		$dist += abs($s[0] - $s[1]) + 1;

		if ($debug) {
		
			print STDERR "dist: dist=$dist\n";
		}
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