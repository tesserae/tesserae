#
# this is a useful way to make changes to the
# BEGIN block of all perl files
#

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

use File::Copy;

# get the list of perl files

my @perl = recursive_search($fs{script}, $fs{cgi});

# change each file

for my $file (@perl) {

	print STDERR "changing $file\n";
	
	my $file_old = $file;
	my $file_new = "$file.alt";

	open (FHI, "<:utf8", $file_old) or die $!;
	open (FHO, ">:utf8", $file_new) or die $!;
	
	my $t = 1;
	
	while (my $line = <FHI>) {
	
		if ($line =~ /BEGIN/) {
		
			$t = 0;
		}
	
		if ($t) {
		
			print FHO $line;
		}
		
		if ($line =~ /# read configuration/) {
		
			print FHO new_text();
			$t = 1;
		}
	}
	
	close FHI;
	close FHO;
	
	move($file_new, $file_old) or die "$!";
}

#
# subroutines
#

sub recursive_search {

	my @dir = @_;
		
	my @perl;

	while (my $dir = shift @dir) {
	
		@dir = @{Tesserae::uniq(\@dir)};
	
		opendir (DH, $dir) or die "can't open directory $dir: $!";
		
		my @files = map { catfile($dir, $_) } grep { !/^\./ } readdir(DH);
			
		for (@files) {
		
			push (@dir, $_) if -d;
			
			push (@perl, $_) if /.pl/;
		}
	}
	
	return (@perl);
}

sub new_text {

	my $new = q|BEGIN {

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
	
	# read configuration|;
	
	return $new;
}