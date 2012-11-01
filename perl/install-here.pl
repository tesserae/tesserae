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

# get the main tesserae directory

my $fs_base	= realpath(catfile($Bin, updir($Bin)));

# set the other directories

my %fs = (

	cgi  => catfile($fs_base , 'cgi-bin'),
	data => catfile($fs_base , 'data'),
	html => catfile($fs_base , 'html'),
	perl => catfile($fs_base , 'perl'),
	test => catfile($fs_base , 'testing'),
	text => catfile($fs_base , 'texts'),
	tmp  => catfile($fs_base , 'tmp'),
	xsl  => catfile($fs_base , 'xsl')
);

# the url paths point to official tesserae site

my $url_base	= 'http://tesserae.caset.buffalo.edu';

my %url = (

	url_cgi		=> $url_base . '/cgi-bin',
	url_css		=> $url_base . '/css',
	url_html	=> $url_base,
	url_image	=> $url_base . '/images',
	url_text	=> $url_base . '/texts',
	url_tmp		=> $url_base . '/tmp',
	url_xsl		=> $url_base . '/xsl'
);

#
# the path to TessSystemVars.pm
# and a copy which we'll modify
#

print STDERR "configuring TessSystemVars.pm\n";

my $file_old = catfile($fs{perl}, "TessSystemVars.pm");
my $file_new = $file_old . ".new";

open (OLD, "<:utf8", $file_old) || die "can't open $file_old: $!"; 
open (NEW, ">:utf8", $file_new) || die "can't open $file_new: $!";

while (my $line = <OLD>) {

	chomp $line;

	$line =~ s/my \$fs_base.*/my \$fs_base = "$fs_base";/;

	for (keys %fs) {
	
		$line =~ s/our \$fs_$_.*/our \$fs_$_ = "$fs{$_}";/;
	}

	$line =~ s/my \$url_base.*/my \$url_base = "$url_base";/;

	for (keys %url) {
	
		$line =~ s/our \$$_.*/our \$$_ = "$url{$_}";/;
	}
	
	$line =~ s/["']Lingua::Stem["']\s*=>\s*[01]/'Lingua::Stem' => 0/;
	$line =~ s/["']Parallel::ForkManager['"]\s*=>\s*[01]/'Parallel::ForkManager' => 0/;
	
	print NEW "$line\n";
}

#
# replace the old TessSystemVars with the new one
#

move($file_new, $file_old);

print STDERR "done\n\n";

#
# run configure
#

print STDERR "configuring remaining files\n";

my $script = catfile($fs{perl}, "configure.pl");

do_cmd("perl $script");

print STDERR "done\n\n";


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

for my $lang (qw/la/) {

	my $script = catfile($fs{perl}, 'v3', 'add_column.pl');
	my $texts  = catfile($fs{text}, $lang, '*');
	
	do_cmd("perl $script $texts");
}

print STDERR "done\n\n";

#
# calculate corpus stats
#

print "calculating corpus-wide frequencies\n";

$script = catfile($fs{perl}, 'v3', 'corpus-stats.pl');

do_cmd("perl $script");

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