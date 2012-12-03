#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# index-ana.pl 
#             
# index words and lines by anagrams

use strict;
use warnings;

use CGI qw(:standard);

use Getopt::Long;
use POSIX;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

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
	
my $file_lang = catfile($fs_data, 'common', 'lang');
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
	
	my $file_index_text  = catfile($fs_data, 'v3', $lang, $text, $text . ".ana_line");				
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

	my $directory = catdir($fs_data, 'v3', $lang);

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