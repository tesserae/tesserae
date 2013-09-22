#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode STDOUT, ':utf8';

# diacritic marks

my $mark  = qr/[\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]/;
my $vowel = qr/[αειηουωΑΕΙΗΟΥΩ]/;

# get files to fix from cmd line args

my @files = grep { -s } @ARGV;

#
# patch
#

for my $file (@files) {

	my $fhi;
	my $fho;
	
	unless (open ($fhi, '<:utf8', $file)) {
		
		warn "Can't read $file: $!";
		next;
	}
	
	# unless (open ($fho, '>:utf8', $file . ".mod")) {
	# 	
	# 	warn "Can't write $file.mod: $!";
	# 	next;
	# }
	
	while (my $line = <$fhi>) {
	
		diag($line);
		# diag(mod($line));
		# last;
	}
	
	close $fhi;
	# close $fho;
}

sub diag {

	my $line = shift;
	
	my @c = split(//, $line);
	
	print $line;
	for (0..$#c) {
	
		print join("\t", $_, $c[$_], ord($c[$_]), sprintf("%04x", ord($c[$_]))) . "\n";
	}
	print "\n";
}

sub mod {

	my $line = shift;

	$line =~ s/($vowel)(${mark}+)/$2$1/g;
	
	return $line;
}