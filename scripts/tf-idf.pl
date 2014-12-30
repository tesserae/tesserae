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
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);

# set parameters

my $quiet = 0;

GetOptions( 'quiet' => \$quiet );

#
# get the list of texts from Tesserae
#

my @lang = @ARGV ? @ARGV : qw/la/;

for my $lang (@lang) {
	
	my $texts = Tesserae::get_textlist($lang, -nopart=>1);

	my ($phrase_count, $text_count) = doc_counts($lang, $texts);
		
	#
	# convert the counts to inverse-document frequency
	#
		
	print STDERR "calculating phrase-specific frequencies\n" unless $quiet;
	
	$phrase_count = normalize($phrase_count, $texts);
		
	print STDERR "calculating document-specific frequencies\n" unless $quiet;
	
	$text_count = normalize($text_count, $texts);
	
	#
	# save
	#
	
	my $file_phrase = catfile($fs{data}, 'common', "$lang.idf_phrase");
	my $file_text   = catfile($fs{data}, 'common', "$lang.idf_text");

	print STDERR "writing $file_phrase\n" unless $quiet;
	nstore $phrase_count, $file_phrase;

	print STDERR "writing $file_text\n" unless $quiet;
	nstore $phrase_count, $file_text;	
}

#
# subroutines
#

sub doc_counts {

	my ($lang, $texts) = @_;
	
	my @texts = @$texts;

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
	
	print STDERR "reading text indices\n" unless $quiet;
	
	my $pr = ProgressBar->new(scalar(@texts), $quiet);
	
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
	
	return (\%phrase_count, \%document_count);
}

sub normalize {

	my ($doc_ref, $corpus_ref) = @_;

	my %doc_count = %$doc_ref;
	my $corpus_size = scalar(@{$corpus_ref});

	my $pr = ProgressBar->new(scalar(keys %doc_count), $quiet);
	
	for (keys %doc_count) {
	
		$pr->advance();
		
		$doc_count{$_} = log($corpus_size/$doc_count{$_});
	}
	
	return \%doc_count;
}