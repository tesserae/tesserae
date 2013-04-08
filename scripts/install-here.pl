# install-here.pl
#
# this script is supposed to provide a one-step
# default install of Tesserae.
#
# It assumes that you want to keep all the
# subdirectories as they come, with the base
# tesserae directory wherever it is now.

use strict;
use warnings;

use Cwd qw/realpath/;
use File::Copy;
use FindBin qw($Bin);
use File::Spec::Functions;

use lib $Bin;
use Tesserae;

# languages to install by default

my @inst_lang     = qw/la/;

#
# build dictionaries
#

print STDERR "building dictionaries\n";

for (qw/build-stem-cache.pl patch-stem-cache.pl build-syn-cache.pl/) {

	my $script = catfile($fs{perl}, $_);

	do_cmd("perl $script");
}

print STDERR "done\n\n";

#
# add texts
#

print STDERR "adding texts\n";

for my $lang (@inst_lang) {

	my $script = catfile($fs{perl}, 'v3', 'add_column.pl');
	my $texts  = catfile($fs{text}, $lang, '*');
	
	do_cmd("perl $script $texts");
}

print STDERR "done\n\n";

#
# calculate corpus stats
#

print "calculating corpus-wide frequencies\n";

my $script = catfile($fs{perl}, 'v3', 'corpus-stats.pl');

my $langs = join(" ", @inst_lang);

do_cmd("perl $script $langs");

print STDERR "done\n\n";


#
# subroutines
#

sub do_cmd {

	my $command = shift;
	
	print STDERR "$command\n";
	
	print STDERR `$command`;
	
	return;
}
