#!/usr/bin/env perl

#
# index_multi.pl
#

=head1 NAME

index_multi.pl - index texts for multi-text searching

=head1 SYNOPSIS

perl index_multi.pl [options] TEXT [TEXT2 [...]]

=head1 DESCRIPTION

Create the indices used to perform multi-text searching.  Right now, multi-text searches
are based on stem-bigrams, pairs of stems that occur anywhere in the same textual unit 
(line/phrase).  The index is created from existing stem indices, so this must be run 
after add_column.pl.

Default use is something like this:

	perl scripts/v3/index_multi.pl texts/la/*
	
The arguments are .tess files just as for add_column.pl, but index_multi.pl does not 
actually read these files; it looks them up in the stem index instead. Does not read
directories the way add_column.pl does, so if you run a whole language subdir as in 
the above example, only full texts will be indexed.  The way we interpret multi-text
results right now, treating every book of a work as a separate hit wouldn't make sense.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang LANG>

Force all texts to be treated as belonging to language LANG.

=item B<--use-lingua-stem>

Use Lingua::Stem instead of build-in stem dictionaries.  Untested in this script!

=item B<--parallel N>

Allow up to N processes to run in parallel.  Requires Parallel::ForkManager.

=item B<--quiet>

Don't print messages to STDERR.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is name.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

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

use CGI qw(:standard);
use POSIX;
use Storable qw(nstore retrieve);
use File::Copy;

# optional modules

my $override_stemmer  = Tesserae::check_mod("Lingua::Stem");
my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

# allow unicode output

binmode STDOUT, ":utf8";

# initialize some variables

my $help = 0;

# number of parallel processes to run

my $max_processes = 0;

# set language

my $lang = 'la';

# these are for optional use of Lingua::Stem

my $use_lingua_stem = 0;
my $stemmer;

# don't print progress info to STDERR

my $quiet = 0;

# features to skip

my %omit;

#
# command-line options
#

GetOptions(
	'lang=s'          => \$lang,
	'parallel=i'      => \$max_processes,
	'quiet'           => \$quiet,
	'use-lingua-stem' => \$use_lingua_stem,
	'help'            => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

# check to make sure stemmer module is available

if ($use_lingua_stem and $override_stemmer) {

	print STDERR 
		"Lingua::Stem was not installed when you configured Tesserae.  "
	   . "If you have installed it since then, please re-configure.  "
	   . "Falling back on stem dictionary method for now.\n";
	   
	$use_lingua_stem = 0;
}

#
# initialize parallel processing
#

my $pm;

if ($max_processes and $override_parallel) {

	print STDERR "Parallel processing requires Parallel::ForkManager from CPAN.\n";
	print STDERR "Proceeding with parallel=0.\n";
	$max_processes = 0;

}

if ($max_processes) {

	$pm = Parallel::ForkManager->new($max_processes);
}

# get the list of texts to index

my @corpus = @{Tesserae::get_textlist($lang, -no_part => 1)};
@corpus = grep { ! /vulgate/ } @corpus;

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

	for my $unit (qw/phrase line/) {
	
		print STDERR "unit: $unit\ntext: $text\n";

		# if the work is prose, don't bother indexing lines

		if ($unit eq 'line' and Tesserae::check_prose_list($text)) {
		
			print STDERR "prose text: skipping line index\n";
			next;
		}
		
		# otherwise, calculate

		my %index_word;
		my %index_stem;
		
		# load the text from the database
		
		my $file_token = catfile($fs{data}, 'v3', $lang, $text, $text . ".token");
		my $file_unit  = catfile($fs{data}, 'v3', $lang, $text, $text . "." . $unit);

		my @token = @{retrieve($file_token)};
		my @unit  = @{retrieve($file_unit)};
		
		# get text- and feature-specific frequencies for scoring

		my $file_freq_word = catfile($fs{data}, 'v3', $lang, $text, $text . ".freq_score_word");
		my $file_freq_stem = catfile($fs{data}, 'v3', $lang, $text, $text . ".freq_score_stem");

		my %freq_word = %{Tesserae::stoplist_hash($file_freq_word)};
		my %freq_stem = %{Tesserae::stoplist_hash($file_freq_stem)};
		
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
					
					my @stems_a = @{Tesserae::feat($lang, 'stem', $form_a)};
					my @stems_b = @{Tesserae::feat($lang, 'stem', $form_b)};
					
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
		
		my $file_index_word = catfile($fs{data}, 'v3', $lang, $text, $text . ".multi_${unit}_word");
		my $file_index_stem = catfile($fs{data}, 'v3', $lang, $text, $text . ".multi_${unit}_stem");

		print STDERR "saving $file_index_word\n";
		nstore \%index_word, $file_index_word;

		unless ($omit{stem}) {

			print STDERR "saving $file_index_stem\n";
			nstore \%index_stem, $file_index_stem;	
		}
	}
	
	$prmanager->finish if $max_processes;
}

$prmanager->wait_all_children if $max_processes;

