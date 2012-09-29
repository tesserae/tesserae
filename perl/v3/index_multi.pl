#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

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

# allow unicode output

binmode STDOUT, ":utf8";

# set language

my $lang = 'la';

# get dictionary

my $file_stem = catfile($fs_data, 'common', $lang . '.stem.cache');

print STDERR "loading stem dictionary $file_stem\n";

my %stem = %{retrieve($file_stem)};

# get the list of texts to index

my @corpus = @{get_textlist($lang)};

# the giant index

print STDERR "indexing " . scalar(@corpus) . " texts...\n";

for my $unit (qw/line phrase/) {
			
	for my $text (@corpus) {

		my %index_word;
		my %index_stem;

		print STDERR "unit: $unit\ntext: $text\n";
		
		# load the text from the database
		
		my $file_token = catfile($fs_data, 'v3', $lang, $text, $text . ".token");
		my $file_unit  = catfile($fs_data, 'v3', $lang, $text, $text . "." . $unit);

		my @token = @{retrieve($file_token)};
		my @unit  = @{retrieve($file_unit)};
		
		# get text- and feature-specific frequencies for scoring

		my $file_freq_word = catfile($fs_data, 'v3', $lang, $text, $text . ".freq_word");
		my $file_freq_stem = catfile($fs_data, 'v3', $lang, $text, $text . ".freq_stem");

		my %freq_word = %{retrieve( $file_freq_word)};
		my %freq_stem = %{retrieve( $file_freq_stem)};
		
		print "indexing " . scalar(@token) . " tokens / " . scalar(@unit) . " ${unit}s...\n";
		
		my $pr = ProgressBar->new(scalar(@unit));
		
		for my $unit_id (0..$#unit) {
			
			$pr->advance();
			
			# these track the unique word- and stem-pairs in the unit

			my %word_pairs;
			my %stem_pairs;
			
			# get the list of tokens in this unit
			
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
					
					my @stems_a = defined $stem{$form_a} ? @{$stem{$form_a}} : ($form_a);
					my @stems_b = defined $stem{$form_b} ? @{$stem{$form_b}} : ($form_b);
					
					next unless @stems_b;
																				
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

		print STDERR "saving $file_index_stem\n";
		nstore \%index_stem, $file_index_stem;	
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
