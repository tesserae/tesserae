#! /usr/bin/perl

# add_column.pl
#
# add a new text to the database

=head1 NAME

add_column.pl - add texts to the tesserae database

=head1 SYNOPSIS

perl add_column.pl [options] TEXT [, TEXT2, [DIR], ...] 

=head1 DESCRIPTION

Reads in one or more .tess documents and creates the indices used by read_table.pl
to perform Tesserae searches.

This script is usually run on an entire directory of texts at once, when you're
first setting Tesserae up.  E.g. (from the Tesserae root dir),

   perl scripts/v3/add_column.pl texts/la/*

If the script is passed a directory instead of a file, it will search inside for
.tess files; this is designed for works which have been partitioned into separate
files, e.g. by internal "book".  These .part. files are stored inside a directory
named for the original work.

If you have a file in the I<texts/> directory called I<prose_list>, this will be
read and any texts whose names are found in the prose list will be added to the
database in "prose mode".  Because the "line" unit of text doesn't make much sense
for prose works, in prose mode the line database is just a copy of the phrase one.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang>

Specify the language code for all texts.  By default tries to guess from the
path, which usually includes this code.  Tells Tesserae where to look for 
stem dictionaries, etc.

=item B<--parllel N>

Allow up to N processes to run in parallel.  Requires Parallel::ForkManager.

=item B<--use-lingua-stem>

Use the Lingua::Stem module to do stemming instead of internal dictionaries.
This is the only way to index English works by stem; I don't think it works
for Latin and almost certainly not for Greek.  The language code will be 
passed to Lingua::Stem, which must have a stemmer for that code.

=item B<--prose>

Force all texts to be added in prose mode.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is add_column.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall <forstall@buffalo.edu>, James Gawley, Neil Coffee

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

use utf8;
use File::Path qw(mkpath rmtree);
use File::Basename;
use File::Copy;
use Storable qw(nstore retrieve);
use Encode;

# optional modules

my $override_stemmer  = Tesserae::check_mod("Lingua::Stem");
my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

#
# splitting phrases
#

# a complicated regex to test for their presence
# if you match this $1 and $2 will be set to the parts
# belonging to the left and right phrases respectively

my $split_punct = qr/(.*"?$phrase_delimiter"?)(\s*)(.*)/;

# 
# initialize some parameters
# 

# these are for optional use of Lingua::Stem

my $use_lingua_stem = 0;
my $stemmer;

#
# for parallel processing
#

my $max_processes = 0;
my $pm;

#
# declare language tools
#

my $lang;

# don't print messages to STDERR 
my $quiet = 0;

# print usage and exit
my $help = 0;

# flag work as prose (not used yet)
my $prose = 0;

# allow utf8 output to stderr
binmode STDERR, ':utf8';

#
# command line options
#

GetOptions( 
	"lang=s"          => \$lang,
	"parallel=i"      => \$max_processes,
	"quiet"           => \$quiet,
	"prose"           => \$prose,
	"use-lingua-stem" => \$use_lingua_stem,
	"help"            => \$help
	);

# print usage if the user needs help
	
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

if ($max_processes and $override_parallel) {

	print STDERR "Parallel processing requires Parallel::ForkManager from CPAN.\n";
	print STDERR "Proceeding with parallel=0.\n";
	$max_processes = 0;

}

if ($max_processes) {

	$pm = Parallel::ForkManager->new($max_processes);
}

# get files to be processed from cmd line args

my @files = map { glob } @ARGV;
my %file = %{Tesserae::process_file_list(\@files, $lang, {filenames=>1})};

unless (keys %file) {

	print STDERR "No files specified\n";
	pod2usage(2);
}

# write the abbreviations database

get_abbr(\%file);

#
# process the files
#

for my $name (keys %file) {
				
	#
	# fork
	#
	
	if ($max_processes) {

		$pm->start and next;
	}
	
	#
	# initialize variables
	#
	
	my @token;
	my @line;
	my @phrase = ({});

	my %index_word;

	my $lang = Tesserae::lang($name);

	#
	# check prose list
	#
	
	my $prose = $prose || Tesserae::check_prose_list($name);
	
	#
	# assume unknown lang is like english
	#
	
	unless (defined $is_word{$lang})  { $is_word{$lang}  = $is_word{en} }
	unless (defined $non_word{$lang}) { $non_word{$lang} = $non_word{en} }

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words

	print STDERR "Reading text: $name\n" unless $quiet;

	# open the input text

	open (TEXT, "<:utf8", $file{$name}) or die("Can't open file ".$file{$name});

	# assume first quote mark is a left one
	
	my $toggle = 1;

	# examine each line of the input text

	while (my $l = <TEXT>) {
		
		chomp $l;

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001>	this is a verse

		$l =~ /^\S*<(.+)>\s+(.+)/;
		
		my ($locus, $verse) = ($1, $2);

		# skip lines with no locus or line

		next unless (defined $locus and defined $verse);
		
		# start a new line
		
		push @line, {};

		# examine the locus of each line

		$locus =~ s/^(.*)\s//;
		
		# save the book/poem/line number

		$line[-1]{LOCUS} = $locus;

		# remove html special chars

		$verse =~ s/&[a-z];//ig;
		$verse =~ s/[<>]//g;

		#
		# check for enjambement with prev line
		#
		
		if (defined $phrase[-1]{TOKEN_ID}) {

			push @token, {TYPE => 'PUNCT', DISPLAY => ' / '};
			push @{$phrase[-1]{TOKEN_ID}}, $#token;
		}
		
		# split the line into tokens				
		# add tokens to the current phrase, line

		while (length($verse) > 0) {
			
			#
			# add word token
			#
			
			if ( $verse =~ s/^($is_word{$lang})// ) {
			
				my $token = $1;
			
				# this display form
				# -- just as it appears in the text

				my $display = $token;
				
				#
				# an experimental feature
				#
				
				if ($token =~ /TESSFORM(.+?)TESSDISPLAY(.+?)/) {
				
					($token, $display) = ($1, $2);
				}

				# convert display greek to unicode

				if ($lang eq "grc") {

					$display = Tesserae::beta_to_uni($display);
				}

				# the searchable form 
				# -- flatten orthographic variation

				my $form = Tesserae::standardize($lang, $token);

				# add the token to the master list

				push @token, { 
					TYPE => 'WORD',
					DISPLAY => $display, 
					FORM => $form ,
					LINE_ID => $#line,
					PHRASE_ID => $#phrase
				};

				# add token id to the line and phrase

				push @{$line[-1]{TOKEN_ID}}, $#token;
				push @{$phrase[-1]{TOKEN_ID}}, $#token;

				# note that this phrase extends over this line

				$phrase[-1]{LINE_ID}{$#line} = 1;
				
				#
				# index
				#
				
				push @{$index_word{$form}}, $#token;				
			}

			#
			# add punct token
			#
			
			elsif ( $verse =~ s/^($non_word{$lang})// ) {
			
				my $token = $1;
				
				# tidy up double quotation marks
				
				while ($token =~ /"/) {

					my $quote = $toggle ? '“' : '”';

					$token =~ s/"/$quote/;

					$toggle = ! $toggle;
				}
			
				# check for phrase-delimiting punctuation
				#
				# if we find any, then this token should
				# be split into two, so that one part can
				# go with each phrase.

				if ($token =~ $split_punct) {

					my ($left, $space, $right) = ($1, $2, $3);

					push @token, {TYPE => 'PUNCT', DISPLAY => $left};

					push @{$line[-1]{TOKEN_ID}}, $#token;
					push @{$phrase[-1]{TOKEN_ID}}, $#token;

					# add intervening white space to the line,
					# but not to either phrase

					if ($space ne '') {

						push @token, {TYPE => 'PUNCT', DISPLAY => $space};
						push @{$line[-1]{TOKEN_ID}}, $#token;
					}

					# start a new phrase

					push @phrase, {};
					
					# now let the body of the function handle what remains

					$token = $right;
				}

				# skip empty strings

				if ($token ne '') {

					# add to the current phrase, line

					push @token, {TYPE => 'PUNCT', DISPLAY => $token};

					push @{$line[-1]{TOKEN_ID}}, $#token;
					push @{$phrase[-1]{TOKEN_ID}}, $#token;
				}
			}
			else {
				
				warn "Can't parse <<$l>> on $name line $.. Skipping.";
				next;
			}			
		}
	}
	
	# if the poem ends with a phrase-delimiting punct token,
	# there will be an empty final phrase;
	# if the poem ends with the sequence ." you can end up
	# with a final phrase composed of " alone.  Check for
	# these and delete
	
	my $haswords = 0;
	
	for (@{$phrase[-1]{TOKEN_ID}}) {
	
		if ($token[$_]{TYPE} eq 'WORD') {
		
			$haswords = 1;
			last;
		}
	}
	
	unless ($haswords) {
	
		push @{$phrase[-2]{TOKEN_ID}}, @{$phrase[-1]{TOKEN_ID}};
	
		pop @phrase;
	}
	
	#
	# tidy up relationship between phrases and lines:
	#  - convert the LINE_ID tag of phrases to a simple array
	#
		
	for my $phrase_id (0..$#phrase) { 
		
		$phrase[$phrase_id]{LINE_ID} = [sort {$a <=> $b} keys %{$phrase[$phrase_id]{LINE_ID}} ];

		# if there's a range, just use the first line
			
		$phrase[$phrase_id]{LOCUS} = $line[$phrase[$phrase_id]{LINE_ID}[0]]{LOCUS};
	}
		
	#
	# save the data
	#
	
	# make sure the directory exists
	
	my $path_data = catfile($fs{data}, 'v3', $lang, $name);
	
	unless (-d $path_data ) { mkpath($path_data) }
	
	my $file_out = catfile($path_data, $name);

	print STDERR "Writing $file_out.token\n" unless $quiet;
	nstore \@token, "$file_out.token";

	print STDERR "Writing $file_out.line\n" unless $quiet;
	nstore \@line, "$file_out.line";
	
	print STDERR "Writing $file_out.phrase\n" unless $quiet;
	nstore \@phrase, "$file_out.phrase";

	print STDERR "Writing $file_out.index_word\n" unless $quiet;
	nstore \%index_word, "$file_out.index_word";
		
	# calculate frequencies for stoplist

	Tesserae::write_freq_stop($name, 'word', \%index_word, $quiet);
	
	# frequencies for score are the same
	
	my $from = catfile($fs{data}, 'v3', $lang, $name, "$name.freq_stop_word");
	my $to   = catfile($fs{data}, 'v3', $lang, $name, "$name.freq_score_word");
	
	print STDERR "Writing $to\n" unless $quiet;
	copy($from, $to);
	
	$pm->finish if $max_processes;
}

$pm->wait_all_children if $max_processes;

#
# subroutines
#

sub get_abbr {

	my $ref = shift;
	
	my %file = %$ref;
	
	my $file_abbr = catfile($fs{data}, 'common', 'abbr');	
	my %abbr = %{retrieve($file_abbr)} if -s $file_abbr;
	
	print STDERR "Getting abbreviations from file tags\n" unless $quiet;
	
	my $pr = ProgressBar->new(scalar(keys %file));
	
	for my $name (keys %file) {
		
		$pr->advance();
	
		# open the input text

		my $fh;

		unless (open ($fh, "<:utf8", $file{$name})) { 
			
			warn "Can't open file $file{$name}: $!";
			next;
		}
		
		my %cit;
		
		while (my $line = <$fh>) {
		
			next unless $line =~ /<(.+?)>/;
			
			my $tag = $1;
			
			$tag =~ s/\s+\S+$//;
			
			$cit{$tag} ++;
		}
		
		my @choice = sort {$cit{$b} <=> $cit{$a}} grep {/\w/} keys %cit;
	
		$abbr{$name} = $choice[0] if $choice[0];
	}
	
	print STDERR "Writing $file_abbr\n";
	
	nstore \%abbr, $file_abbr;
}