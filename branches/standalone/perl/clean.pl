#
# delete stored data from the database
#

use strict;
use warnings; 

use FindBin qw($Bin);

use lib $Bin;
use TessSystemVars;
use EasyProgressBar;

use File::Path qw(mkpath rmtree);
use File::Basename;
use Cwd;
use Storable qw(nstore retrieve);
use Getopt::Long;

my $target = "all";

if ($target eq "text") {

	rmtree "$fs_data/v3";
	mkpath "$fs_data/v3";
}

if ($target ne "all") {

	unlink "$fs_data/common/abbr";
	unlink "$fs_data/common/lang";	
}
else {

	rmtree "$fs_data/common";
	mkpath "$fs_data/common";
}