#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# title 
#

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

use if $ancillary{"Lingua::Stem"}, "Lingua::Stem";
use if $ancillary{"Parallel::ForkManager"}, "Parallel::ForkManager";

# allow unicode output

binmode STDOUT, ":utf8";

# number of parallel processes to run

my $max_processes = 0;

# set language

my $lang = 'la';

# these are for optional use of Lingua::Stem

my $use_lingua_stem = 0;
my $stemmer;

# don't print progress info to STDERR

my $quiet = 0;

#
# command-line options
#

GetOptions(
	"lang=s"          => \$lang,
	"parallel=i"      => \$max_processes,
	"quiet"           => \$quiet,
	"use-lingua-stem" => \$use_lingua_stem
	);

#		
# get dictionaries
#

my %stem;
my %syn;

my $file_stem = catfile($fs_data, 'common', $lang . '.stem.cache');
my $file_syn  = catfile($fs_data, 'common', $lang . '.syn.cache');

my %omit;

if (-r $file_stem or $use_lingua_stem) {
		
	if ($use_lingua_stem) {
	
		$stemmer = Lingua::Stem->new({-locale => $lang});
	}
	else {
	
		%stem = %{ retrieve($file_stem) };
	}
	
	if (-r $file_syn) {

		%syn = %{ retrieve($file_syn) };
	}
	else {
		
		print STDERR "Can't find syn dictionary!  Syn indexing disabled.\n" unless $quiet;
		$omit{syn} = 1;
	}
}
else {
	
	print STDERR "Can't find stem dictionary! Stem and syn indexing disabled.\n" unless $quiet;
	$omit{stem} = 1;
}


# get the list of texts to index

my @corpus = @{get_textlist($lang)};

# the giant index

print STDERR "indexing " . scalar(@corpus) . " texts...\n";

for my $unit (qw/line phrase/) {
	
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

		my %index_word;
		my %index_stem;

		print STDERR "unit: $unit\ntext: $text\n";
		
		# load the text from the database
		
		my $file_token = catfile($fs_data, 'v3', $lang, $text, $text . ".token");
		my $file_unit  = catfile($fs_data, 'v3', $lang, $text, $text . "." . $unit);

		my @token = @{retrieve($file_token)};
		my @unit  = @{retrieve($file_unit)};
		
		# get text- and feature-specific frequencies for scoring

		my $file_freq_word = catfile($fs_data, 'v3', $lang, $text, $text . ".freq_score_word");
		my $file_freq_stem = catfile($fs_data, 'v3', $lang, $text, $text . ".freq_score_stem");

		my %freq_word = %{TessSystemVars::stoplist_hash($file_freq_word)};
		my %freq_stem = %{TessSystemVars::stoplist_hash($file_freq_stem)};
		
		print "indexing " . scalar(@token) . " tokens / " . scalar(@unit) . " ${unit}s...\n";
				
		for my $unit_id (0..$#unit) {
			
			# these track the unique word- and stem-pairs in the unit

			my %word_pairs;
			my %stem_pairs;
			
			# get the list of tokens in this unit
			
			next unless defined $unit[$unit_id]{TOKEN_ID};
			
			my @tokens = @{$unit[$unit_id]{TOKEN_ID}};
				
			# check every possible pair
		
			for my $i (0..$#tokens-1) {
				
				my $token_id_a = $tokens[$i];

				# skip punctuation tokens
				
				next if $token[$token_id_a]{TYPE} ne 'WORD';
				
				for my $j ($i+1..$#tokens) {
					
					my $token_id_b = $tokens[$j];
					
					next if $token[$token_id_b]{TYPE} ne 'WORD';
					
					# first check the forms.
					
					my $form_a = $token[$token_id_a]{FORM};
					my $form_b = $token[$token_id_b]{FORM};
					
					# if they're identical, then stems will be too.
					# don't bother indexing
					
					next if $form_a eq $form_b;
					
					# index this unit by this pair of forms
					
					my $score = log((1/$freq_word{$form_a} + 1/$freq_word{$form_b}) / ($j - $i));

					$word_pairs{join("~", sort($form_a, $form_b))} = $score;

					# now check stems
					
					next if $omit{stem};
					
					my @stems_a = @{stems($form_a)};
					my @stems_b = @{stems($form_b)};
					
					for my $stem_a (@stems_a) {
						
						for my $stem_b (@stems_b) {
							
							my $score = log((1/$freq_stem{$form_a} + 1/$freq_stem{$form_b}) / ($j - $i));
							
							$stem_pairs{join("~", sort($stem_a, $stem_b))} = $score;
						}
					}					
				}
			}
			
			# index the unit for each pair

			for (keys %word_pairs) {
				
				$index_word{$_}{$unit_id} = $word_pairs{$_};
			}
			
			for (keys %stem_pairs) {
				
				$index_stem{$_}{$unit_id} = $stem_pairs{$_};
			}
		}
		
		my $file_index_word = catfile($fs_data, 'v3', $lang, $text, $text . ".multi_${unit}_word");
		my $file_index_stem = catfile($fs_data, 'v3', $lang, $text, $text . ".multi_${unit}_stem");

		print STDERR "saving $file_index_word\n";
		nstore \%index_word, $file_index_word;

		unless ($omit{stem}) {

			print STDERR "saving $file_index_stem\n";
			nstore \%index_stem, $file_index_stem;	
		}
		
		# wrap up child process
		
		if ($max_processes) {

			$prmanager->finish;
		}
	}	
	
	# clean up child processes before next loop
	
	if ($max_processes) {
	
		$prmanager->wait_all_children;
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

sub stems {

	my $form = shift;
	
	my @stems;
	
	if ($use_lingua_stem) {
	
		@stems = @{$stemmer->stem($form)};
	}
	elsif (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}

sub syns {

	my $form = shift;
	
	my %syns;
	
	for my $stem (@{stems($form)}) {
	
		if (defined $syn{$stem}) {
		
			for (@{$syn{$stem}}) {
			
				$syns{$_} = 1;
			}
		}
	}
	
	return [keys %syns];
}
