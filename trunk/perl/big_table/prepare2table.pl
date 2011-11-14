#! /opt/local/bin/perl
use lib '/Users/chris/Desktop/tesserae/perl';

# prepare2table.pl
#
# try to turn roelant's parsed binaries into an inverted index

use strict;
use warnings; 

use TessSystemVars;
use Storable;

my $name = 'vergil.aeneid';

my $file_in = "$fs_data/v2/parsed/$name
