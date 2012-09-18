#! /usr/bin/perl

# this is to examine a data structure saved with Storable
#
# it assumes the storable file contains an array of records
# and prints out the first one in its entirety.

use strict;
use warnings;
use Storable;

binmode STDOUT, ":utf8";

my $file = shift @ARGV || die "specify binary to diagnose";
my $i = shift @ARGV || 0;

my $ref = retrieve($file);

if (ref($ref) eq "ARRAY") {
	
	my @rec = @$ref;

	my %field = %{ $rec[$i] };
	
	for my $key ( sort keys %field ) {

		my $value;
		
		if (ref($field{$key}) eq "ARRAY") {
			
			my @array;
			for (@{$field{$key}}) {
				
				push @array, "'$_'";
			}
			
			$value = "[" . join(", ", @array) . "]";
		}
		else {
			
			$value = "'$field{$key}'";
		}
		
		print sprintf("%-9s\t%s\n", $key, $value);
	}
}
elsif (ref($ref) eq "HASH") {
	
	my %index = %$ref;
	
	my $key = (sort keys %index)[0];
	
	my $value;
	
	if (ref($index{$key}) eq "ARRAY") {
		
		my @array;
		for (@{$index{$key}}) {
			
			push @array, "'$_'";
		}
		
		$value = "[" . join(", ", @array) . "]";
	}
	else {
		
		$value = "'$index{$key}'";
	}
	
	print sprintf("%-9s\t%s\n", $key, $value);
}