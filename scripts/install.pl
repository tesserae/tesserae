use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}	
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script


# initialize some variables

my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

# languages to install by default

my @inst_lang    = qw/la grc/;
my @inst_feature = qw/stem 3gr/;

#
# build dictionaries
#

print STDERR "building dictionaries\n";

do_cmd("perl " . catfile($fs{script}, 'build-stem-cache.pl '. join(" ", @inst_lang)));
do_cmd("perl " . catfile($fs{script}, 'patch-stem-cache.pl'));

print STDERR "done\n\n";

#
# add texts
#

print STDERR "adding texts\n";

for my $lang (@inst_lang) {

	my $script = catfile($fs{script}, 'v3', 'add_column.pl');
	my $texts  = catfile($fs{text}, $lang, '*');
	
	do_cmd("perl $script $texts");

	for my $feature (@inst_feature) {
		
		$script = catfile($fs{script}, 'v3', 'add_col_stem.pl --feat $feature');
	
		do_cmd("perl $script $texts");
	}
}

print STDERR "done\n\n";

#
# calculate corpus stats
#
{
	print "calculating corpus-wide frequencies\n";
	
	my $script = catfile($fs{script}, 'v3', 'corpus-stats.pl');
	
	my $features = join(" ", map {"--feat $_"} @inst_feature);
	
	my $langs = join(" ", @inst_lang);
	
	do_cmd("perl $script $features $langs");
	
	print STDERR "done\n\n";
}

#
# create drop-down lists
#

{

	my $script = catfile($fs{script}, 'textlist.pl');
	my $langs = join(" ", @inst_lang);

	do_cmd("perl $script $langs");
}

#
# subroutines
#

sub do_cmd {

	my $command = shift;
	
	print STDERR "$command\n";
	
	print STDERR `$command`;
	
	return;
}

