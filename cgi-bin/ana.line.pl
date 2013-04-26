#!/usr/bin/env perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Desktop/tesserae/perl';	# PERL_PATH

#
# index-ana.pl 
#             
# index words and lines by anagrams

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

use CGI qw(:standard);

use POSIX;
use Storable qw(nstore retrieve);

# allow unicode output

binmode STDOUT, ":utf8";

# don't print progress info to STDERR

my $quiet = 0;

#
# command-line options
#

GetOptions(
	"quiet"           => \$quiet,
	);

# language info
	
my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# get the list of texts to index

my @corpus;

if (@ARGV) {
	
	@corpus = @ARGV;
}
else {

   @corpus = @{get_textlist("la")};
}

# the giant index

my %index;

print STDERR "checking " . scalar(@corpus) . " texts...\n";
				
for my $text (@corpus) {

	print STDERR "$text\n";
	                                         
	# get language info
	
	my $lang = $lang{$text};
	
	# load the text from the database
	
	my $file_index_text  = catfile($fs{data}, 'v3', $lang, $text, $text . ".ana_line");				
	my %index_text = %{retrieve($file_index_text)};
	
	# add to giant index
	
	while (my ($key, $values) = each %index_text) {
	                              
		push @{$index{$key}}, @{$values};
	}
}	   

#
# print all anagrams shared by 2 or more lines
#                                             

print STDERR "writing output\n";

while (my ($key, $values) = each %index) {
 
	if (scalar(@$values) > 2) {
	                 
		print "$key\n";
	
		for (@{$values}) {
			
			print "\t$$_{text}\t$$_{id}\t$$_{line}\n";
	   }                                   
		
		print "\n";
  }
}


sub get_textlist {
	
	my $lang = shift;

	my $directory = catdir($fs{data}, 'v3', $lang);

	opendir(DH, $directory);
	
	my @textlist = grep {/^[^.]/ && ! /\.part\./} readdir(DH);
	
	closedir(DH);
		
	return \@textlist;
}

sub ana {
 
	my $string = shift;
	
	my @letters = split //, $string;
	
	my $ana = join("", sort @letters);
	
	return $ana;
}