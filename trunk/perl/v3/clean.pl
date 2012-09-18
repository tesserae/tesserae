#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

# clean.pl
#
# delete existing data

use strict;
use warnings; 

use TessSystemVars;

use File::Path qw(mkpath rmtree);
use File::Spec::Functions;
use File::Basename;
use Cwd;
use Storable qw(nstore retrieve);
use Getopt::Long;

my %clean = (
	text => 0,
	dict => 0
			 );
			
GetOptions( "text" => \$clean{text}, "dict" => \$clean{dict} );

# specify languages to clean as arguments

my @lang = @ARGV;

# if none specified, clean all

unless (@lang) {

	opendir (DH, catdir($fs_data, 'v3'));
	
	@lang = grep {/^[^.]/ && -d catdir($fs_data, 'v3', $_) } readdir DH;
	
	closedir DH;
}

# these will be modified to remove deleted texts

my %abbr = %{ retrieve(catfile($fs_data, 'common', 'abbr')) };
my %lang = %{ retrieve(catfile($fs_data, 'common', 'lang')) };

# clear preprocessed texts from the database

if ($clean{text}) {
	
	for (@lang) { 
	
		rmtree catdir($fs_data, 'v3', $_);
		mkpath catdir($fs_data, 'v3', $_);

		unlink glob(catfile($fs_data, 'common', $_ . '.*.count'));
	}
	
	for my $text (keys %abbr) {
	
		if (grep {/$lang{$text}/} @lang) {
		
			delete $abbr{$text};
			delete $lang{$text};
		}
	}
}

# save changes

nstore \%abbr, catfile($fs_data, 'common', 'abbr');
nstore \%lang, catfile($fs_data, 'common', 'lang');

# remove dictionaries

if ($clean{dict}) {

	for (@lang) {

		unlink glob(catfile($fs_data, 'common', $_ . '.*.cache'));
	}
}
