#! /opt/local/bin/perl

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
	text => 1,
	dict => 1
			 );

# clear preprocessed texts from the database

if ($clean{text}) {
	
	rmtree catfile($fs_data, 'v3');
	mkpath catfile($fs_data, 'v3');
	
	unlink catfile($fs_data, 'common', 'abbr');	
	unlink catfile($fs_data, 'common', 'lang');
	
	unlink glob(catfile($fs_data, 'common', 'la.*.count'));
}

if ($clean{dict}) {

	unlink glob(catfile($fs_data, 'common', 'la.*.cache'));
}
