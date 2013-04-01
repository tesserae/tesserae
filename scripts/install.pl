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
	
	my $config = catfile($lib, 'tesserae.conf');
		
	until (-s $config) {
					
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			$config = catfile($lib, 'tesserae.conf');
			
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

use lib $fs{perl};

use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use File::Copy;

# copy tesserae.conf and Tesserae.pm
# to cgi-bin directory

for my $file (qw/tesserae.conf Tesserae.pm EasyProgressBar.pm/) {

	my $here  = catfile($Bin,     $file);
	my $there = catfile($fs{cgi}, $file);

	copy($here, $there) or die "can't copy $here to $there: $!";
	
	print STDERR "copying $here to $there\n";
}

# create var definition files for php and xsl

create_php_defs(catfile($fs{html}, 'defs.php'));
create_xsl_defs(catfile($fs{xsl},  'defs.xsl'));

#
# subroutines
#

#
# Create defs.xsl,
#    containing system vars used by xsl files
#

sub create_xsl_defs {

	my $file = shift;

	open (FH, ">:utf8", $file) or die "can't create file $file: $!";
	
	print STDERR "writing $file\n";
	
	print FH <<END;
	
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:variable name="url_cgi"   select="'$url{cgi}'" />
	<xsl:variable name="url_css"   select="'$url{css}'" />
	<xsl:variable name="url_html"  select="'$url{html}'" />
	<xsl:variable name="url_image" select="'$url{image}'" />
	<xsl:variable name="url_text"  select="'$url{text}'" />
	
</xsl:stylesheet>
END

	close FH;
	return;
}

#
# Create defs.php, 
#   containing system vars used by php files
#

sub create_php_defs {

	my $file = shift;

	open (FH, ">:utf8", $file) or die "can't create file $file: $!";

	print STDERR "writing $file\n";
	
	print FH <<END;
		
<?php \$url_html  = "$url{html}" ?>
<?php \$url_css   = "$url{css}" ?>
<?php \$url_cgi   = "$url{cgi}" ?>
<?php \$url_image = "$url{image}" ?>
<?php \$url_text  = "$url{text}" ?>
<?php \$fs_html   = "$fs{html}" ?>

END
	
	close FH;
	return;
}