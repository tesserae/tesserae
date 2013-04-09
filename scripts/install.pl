use strict;
use warnings;

#
# Read configuration file
#

# variables set from config

my %fs;
my %url;
my $lib;

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $config;
	my $pointer;
			
	while (1) {

		$config  = catfile($lib, 'tesserae.conf');
		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-s $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$config = <FH>;
			
			chomp $config;
			
			last;
		}
		
		last if (-s $config);
							
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find tesserae.conf!\n";
	}
	
	# read configuration		
	my %par;
	
	open (FH, $config) or die "can't open $config: $!";
	
	while (my $line = <FH>) {
	
		chomp $line;
	
		$line =~ s/#.*//;
		
		next unless $line =~ /(\S+)\s*=\s*(\S+)/;
		
		my ($name, $value) = ($1, $2);
			
		$par{$name} = $value;
	}
	
	close FH;
	
	# extract fs and url paths
		
	for my $p (keys %par) {

		if    ($p =~ /^fs_(\S+)/)		{ $fs{$1}  = $par{$p} }
		elsif ($p =~ /^url_(\S+)/)		{ $url{$1} = $par{$p} }
	}
}

# load Tesserae-specific modules

use lib $fs{script};

use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

# languages to install by default

my @inst_lang = qw/la/;

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

