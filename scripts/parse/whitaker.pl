# parse the dictionary file for whitaker's words
# and use the english defs for semantic tags

use lib '/Users/chris/tesserae/perl';

use strict;
use warnings;

use TessSystemVars;

use Storable qw(nstore retrieve);

my $file_semantic	= "$fs_data/common/la.semantic.cache";
my $file_stem		= "$fs_data/common/la.stem.cache";
my $file_count		= "$fs_data/common/la.word_count";
my $file_whitaker	= "$fs_data/common/DICTPAGE.RAW";


my %count	= %{ retrieve($file_count) };
my %stem	= %{ retrieve($file_stem)  };

my %tesserae;

for my $form (	keys %count ) {

	if (defined $stem{$form}) {
		
		for (@{$stem{$form}}) {
			
			$tesserae{$_} = 1;
		}
	}
	else {
		
		$tesserae{$form} = 1;
	}
}

print "tesserae has " . scalar(keys %tesserae) . " forms to look up\n";

#
# parse whitaker
#

my %whitaker;

open FH, $file_whitaker;

while (<FH>) {
	
	chomp;
	
	if (/\#(\S+)[,\s].*:: (.+)/) {
		
		my ($key, $def) = ($1, $2);
		
		$whitaker{$key} = $def;
	}
}

close FH;

print "whitaker has " . scalar(keys %whitaker) . " entries\n";

#
# associate the defs with the tesserae words
#

my %def;

for (keys %tesserae) {
	
	$def{$_} = $whitaker{$_};
}

print scalar(keys %def) . "/" . scalar(keys %tesserae) . " tesserae words have defs\n";

nstore \%def, $file_semantic;