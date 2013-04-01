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

# optional modules

use if $ancillary{"Parallel::ForkManager"}, "Parallel::ForkManager";

# allow unicode output

binmode STDOUT, ":utf8";

# number of parallel processes to run

my $max_processes = 0;

# don't print progress info to STDERR

my $quiet = 0;

#
# command-line options
#

GetOptions(
	"parallel=i"      => \$max_processes,
	"quiet"           => \$quiet,
	);

# language info
	
my $file_lang = catfile($fs_data, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# get the list of texts to index

my @corpus = @ARGV || @{get_textlist("la")};

# the giant index

print STDERR "indexing " . scalar(@corpus) . " texts...\n";
	
# initialize process manager

my $prmanager;

if ($max_processes) {

	$prmanager = Parallel::ForkManager->new($max_processes);
}
			
for my $text (@corpus) {

	# fork
	
	if ($max_processes) {
	
		$prmanager->start and next;
	}

	my %index_token;
	my %index_line;

	print STDERR "$text:";
	                                         
	# get language info
	
	my $lang = $lang{$text};
	
	# load the text from the database
	
	my $file_token = catfile($fs_data, 'v3', $lang, $text, $text . ".token");
	my $file_line  = catfile($fs_data, 'v3', $lang, $text, $text . ".line");

	my @token = @{retrieve($file_token)};
	my @line  = @{retrieve($file_line)};
			
	print STDERR scalar(@token) . " tokens / " . scalar(@line) . " lines...\n";
				
	for my $line_id (0..$#line) {
					
		# get the list of tokens in this unit
		
		my @tokens = @{$line[$line_id]{TOKEN_ID}};
			                                       
		# this will collect all the words in the line
		
		my @words;
			
		# anagrammatize each word 
	                            
		for my $token_id (@tokens) {
		 
			next unless $token[$token_id]{TYPE} eq "WORD";
			
			my $form = $token[$token_id]{FORM};       
			
			unless (defined $form) {
			 
				print STDERR "$text token $token_id (line $line_id) has no form!\n";
				next;
			}
			
			push @{$index_token{ana($form)}}, $token_id;
			
			push @words, $form;
		}		                                   
		
		unless (@words) {
		 
			print STDERR "$text line $line_id has no words!\n";
			next;
		} 
		
		# index the whole line as an anagram
		                       
		my $line_string = join(" ", @words);
		
		push @{$index_line{ana($line_string)}}, {text => $text, id => $line_id, line => $line_string}; 
	}
		
	my $file_index_token = catfile($fs_data, 'v3', $lang, $text, $text . ".ana_token");
	my $file_index_line  = catfile($fs_data, 'v3', $lang, $text, $text . ".ana_line");

	print STDERR "saving $file_index_token\n";
	nstore \%index_token, $file_index_token;

	print STDERR "saving $file_index_line\n";
	nstore \%index_line, $file_index_line;	
		
	# wrap up child process
	
	if ($max_processes) {

		$prmanager->finish;
	}
} 

$prmanager->wait_all_children if ($max_processes);  
	

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