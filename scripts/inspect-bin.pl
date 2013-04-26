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

if (ref($ref) eq "HASH") { 

	my %index = %$ref;
	
	print expand($index{$i}) if defined $index{$i};
}
elsif (ref($ref) eq "ARRAY") {

	my @val = @$ref;
	
	print expand($val[$i]) if defined $val[$i];
}


sub expand {

	my ($ref, $indent) = @_;
	
	$indent = 0 unless defined $indent;

	return 
		ref($ref) eq "HASH"   ? expand_hash($ref, $indent)   :
		ref($ref) eq "ARRAY"  ? expand_array($ref, $indent)  :
		ref($ref) eq "SCALAR" ? expand_scalar($ref, $indent) :
								$ref;
}

sub expand_hash {

	my ($ref, $indent) = @_;
	
	$indent++;
	
	my %index = %$ref;
	
	my $return = " "x($indent-1) . "{\n";
	
	while (my ($key, $value) = each %index) {
			
		$return .= " "x$indent . sprintf("%-9s => %s\n", $key, expand($value, $indent));
	}
	
	$return .= " "x($indent-1) . "}\n";
}

sub expand_array {

	my ($ref, $indent) = @_;
	
	my @array = @$ref;
	
	for (@array) {
	
		my $val = expand($_, $indent);
	
		if ($val =~ /\D/) { $val = "\"$val\"" }
		
		$_ = $val;
	}
				
	return "[" . join(", ", @array) . "]";
}

sub expand_scalar {

	my ($ref, $indent) = @_;
	
	return $$ref;
}
