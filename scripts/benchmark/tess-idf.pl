# create a database of inverse-document frequencies for all words in Tesserae
#
# created for large-scale score tests
# 
# Chris Forstall
# 2012-06-08

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

use Storable qw(nstore retrieve);

#
# get the list of texts from Tesserae
#

my $lang = "la";

my @texts = @{get_textlist($lang)};

#
# do a word count for every phrase and every text
#

# this counts the number of phrases containing each word

my %phrase_count;

# this counts the total number of phrases in the whole corpus

my $total_phrases = 0;

# this counts the number of documents containing each word

my %document_count;

# check each text's index:

print STDERR "reading text indices\n";

my $pr = ProgressBar->new(scalar(@texts));

for my $text (@texts) {
		
	$pr->advance();
	
	my %seen;
	
	my $file_token = catfile($fs{data}, 'v3', $lang, $text, "$text.token");
	
	my @token  = @{retrieve($file_token)};
	
	for my $token (@token) {
			
		next unless $$token{TYPE} eq "WORD";
			
		$seen{$$token{FORM}}{$$token{PHRASE_ID}} = 1;
	}
	
	for my $word (keys %seen) {
	
		$document_count{$word}++;
		$phrase_count{$word} += scalar(keys %{$seen{$word}});
	}
	
	for (my $i = $#token; $i >= 0; $i--) {
	
		if (defined $token[$i]{PHRASE_ID}) {

			$total_phrases += $token[$i]{PHRASE_ID};
			last;
		}
	}
}

#
# convert the counts to inverse-document frequency
#

print STDERR "calculating document-specific frequencies\n";

$pr = ProgressBar->new(scalar keys %document_count);

for (keys %document_count) {

	$pr->advance();
	
	$document_count{$_} = log(scalar(@texts)/$document_count{$_});
}

print STDERR "calculating phrase-specific frequencies\n";

$pr = ProgressBar->new(scalar keys %document_count);

for (keys %phrase_count) {
	
	$pr->advance();

	$phrase_count{$_} = log($total_phrases/$phrase_count{$_});
}

#
# save
#

nstore \%document_count, "data/la.idf_text";
nstore \%phrase_count, "data/la.idf_phrase";

#
# subroutines
#

sub get_textlist {
	
	my $lang = shift;
	
	my $directory = catdir($fs{data}, 'v3', $lang);

	opendir(DH, $directory);
	
	my @textlist = grep {/^[^.]/ && ! /[\._]part[\._]/} readdir(DH);
	
	closedir(DH);
		
	return \@textlist;
}