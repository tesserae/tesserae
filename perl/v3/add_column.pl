#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

# add_column.pl
#
# add a new text to the database

use strict;
use warnings; 

use TessSystemVars;

use utf8;
use File::Path qw(mkpath rmtree);
use File::Spec::Functions;
use File::Basename;
use Cwd;
use Storable qw(nstore retrieve);
use Parallel::ForkManager;
use Getopt::Long;

#
# splitting phrases
#

# a complicated regex to test for their presence
# if you match this $1 and $2 will be set to the parts
# belonging to the left and right phrases respectively

my $split_punct = qr/(.*"?$phrase_delimiter"?)(\s*)(.*)/;

# 
# some parameters
# 

my %abbr;
my $file_abbr = catfile($fs_data,'common', 'abbr');
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

my %lang;
my $file_lang = catfile($fs_data, 'common', 'lang');

#
# command line options
#

# force language of input files

my $lang;

# number of processes to run in parallel

my $max_processes = 0;

# check user options

GetOptions( 
	"lang=s" => \$lang, 
	"processes=i" => \$max_processes
	);

#
# initialize process manager for parallel processing
#

my $prmanager = Parallel::ForkManager->new($max_processes);

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV) {
	
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if (-d $file_in) {

		opendir (DH, $file_in);

		my @parts = (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

		push @ARGV, @parts;
			
		closedir (DH);
		
		# move on to the next full text

		next;
	}
	
	my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
	next unless ($suffix eq ".tess");
	
	$prmanager->start and next;
	
	# get the language for this doc.  try:
	# 1. user specified at cmd line
	# 2. cached from a previous successful parse
	# 3. somewhere in the path to the text
	# - then give up

	if ( defined $lang and $lang ne "") {
	}
	elsif ( defined $lang{$name} ) {

		$lang = $lang{$name};
	}
	elsif (Cwd::abs_path($file_in) =~ m/$fs_text\/([a-z]{1,4})\//) {

		$lang = $1;
	}
	else {

		print STDERR "Can't guess the language of $file_in! Try reprocessing with --lang LANG\n";
		next;
	}
	
	if (-s $file_lang )	{ %lang = %{retrieve($file_lang)} }
	
	#
	# initialize variables
	#
	
	my @token;
	my @line;
	my @phrase = ({});

	my %ref;

	my %index_form;
	my %index_stem;
	my %index_syn;

	#
	# check for the dictionaries
	#
	
	my %stem;
	my %syn;
	
	my $file_stem = catfile($fs_data, 'common', "$lang.stem.cache");
	my $file_syn  = catfile($fs_data, 'common', "$lang.syn.cache");
	
	my $no_stems;
	my $no_syns;
	
	if (-r $file_stem) {
		
		%stem = %{ retrieve($file_stem) };
		
		if (-r $file_syn) {
	
			%syn = %{ retrieve($file_syn) };
		}
		else {
			
			print STDERR "Can't find syn dictionary!  Syn indexing disabled.\n";
			$no_syns = 1;
		}
	}
	else {
		
		print STDERR "Can't find stem dictionary! Stem and syn indexing disabled.\n";
		$no_stems = 1;		
	}
	
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

	print STDERR "reading text: $file_in\n";

	# open the input text

	open (TEXT, "<:utf8", $file_in) or die("Can't open file ".$file_in);

	# assume first quote mark is a left one
	
	my $toggle = 1;

	# examine each line of the input text

	while (my $l = <TEXT>) {
		
		chomp $l;

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001>	this is a verse

		$l =~ /^<(.+)>\s+(.+)/;
		
		my ($locus, $verse) = ($1, $2);

		# skip lines with no locus or line

		next unless (defined $locus and defined $verse);
		
		# start a new line
		
		push @line, {};

		# examine the locus of each line

		$locus =~ s/^(.*)\s//;
		
		# save the abbreviation of the author/work
		
		$ref{$1}++;

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

				if ($lang eq "grc") {

					$display = TessSystemVars::beta_to_uni($display);
				}

				# the searchable form 
				# -- flatten orthographic variation

				my $form = TessSystemVars::lcase($lang, $token);
				$form = TessSystemVars::standardize($lang, $form);

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
				
				# by form
				
				push @{$index_form{$form}}, $#token;
				
				# by stem
				
				next if $no_stems;
				
				my @stems = defined $stem{$form} ? @{$stem{$form}} : ($form);
				
				for my $stem (@stems) {
				
					push @{$index_stem{$stem}}, $#token;
				}
				
				# by syn
				
				next if $no_syns;
				
				my %syns;
				
				for my $stem (@stems) {
				
					$syns{$stem} = 1;
					
					if (defined $syn{$stem}) {
					
						for my $syn (@{$syn{$stem}}) {
							$syns{$syn} = 1;
						}
					}
				}
				
				for my $syn (keys %syns) {
				
					push @{$index_syn{$syn}}, $#token;
				}
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
				
				warn "Can't parse <<$l>> on $file_in line $.. Skipping.";
				next;
			}			
		}
	}
	
	# if the poem ends with a phrase-delimiting punct token,
	# there will be an empty final phrase -- delete if exists
	
	pop @phrase unless defined $phrase[-1]{TOKEN_ID};
	
	#
	# tidy up relationship between phrases and lines:
	#  - convert the LINE_ID tag of phrases to a simple array
	#
		
	for my $phrase_id (0..$#phrase) { 
		
		$phrase[$phrase_id]{LINE_ID} = [sort {$a <=> $b} keys %{$phrase[$phrase_id]{LINE_ID}} ];

		# if there's a range, make it easy to read;
			
		$phrase[$phrase_id]{LOCUS} = $line[$phrase[$phrase_id]{LINE_ID}[0]]{LOCUS};
	}
		
	#
	# save the data
	#
	
	# make sure the directory exists
	
	my $path_data = catfile($fs_data, 'v3', $lang, $name);
	
	unless (-d $path_data ) { mkpath($path_data) }

	my $file_out = catfile($path_data, $name);

	print "writing $file_out.token\n";
	nstore \@token, "$file_out.token";

	print "writing $file_out.line\n";
	nstore \@line, "$file_out.line";
	
	print "writing $file_out.phrase\n";
	nstore \@phrase, "$file_out.phrase";

	print "writing $file_out.index_word\n";
	nstore \%index_form, "$file_out.index_word";
	
	print "writing $file_out.freq_word\n";
	nstore freq_from_index(\%index_form), "$file_out.freq_word";

	print "writing $file_out.stop_word\n";
	nstore freq_from_index(\%index_form), "$file_out.stop_word";

	unless ($no_stems) {
		
		print "writing $file_out.index_stem\n";
		nstore \%index_stem, "$file_out.index_stem";
		
		print "writing $file_out.freq_stem\n";
		nstore stem_freq(\%index_form, \%stem), "$file_out.freq_stem";
		
		print "writing $file_out.stop_stem\n";
		nstore freq_from_index(\%index_stem), "$file_out.stop_stem";
	}
	unless ($no_syns) {
		
		print "writing $file_out.index_syn\n";
		nstore \%index_syn, "$file_out.index_syn";
		
		print "writing $file_out.freq_syn\n";
		nstore syn_freq(\%index_form, \%stem, \%syn), "$file_out.freq_syn";
		
		print "writing $file_out.stop_syn\n";
		nstore freq_from_index(\%index_syn), "$file_out.stop_syn";

	}


	# add this ref to the database of abbreviations

	unless (defined $abbr{$name})
	{	
		$abbr{$name} = (sort { $ref{$b} <=> $ref{$a} } keys %ref)[0];
		nstore \%abbr, $file_abbr;
	}

	# save the language designation for this file

	unless (defined $lang{$name})
	{
		$lang{$name} = $lang;
		nstore \%lang, $file_lang;
	}
	
	# wrap up child process
	
	$prmanager->finish;
}

# make sure all processes are done

$prmanager->wait_all_children;

sub freq_from_index {
	
	my $index_ref = shift;
	
	my %index = %$index_ref;
	
	my %freq;
	
	my $total = 0;
	
	for (keys %index) {
		
		$total += scalar(@{$index{$_}});
	}
	
	for (keys %index) {
		
		$freq{$_} = scalar(@{$index{$_}})/$total;
	}
	
	return \%freq;
}

sub stem_freq {

	my ($index_ref, $stem_ref) = @_[0,1];
	my %index = %$index_ref;
	my %stem = %$stem_ref;
		
	my %by_stem;
	my %count;
	my $total;

	# count and index words
	
	for my $word (keys %index) {

		$count{$word} += scalar(@{$index{$word}});
		
		$total += $count{$word};
		
		next unless defined $stem{$word};
		
		for my $stem ( @{$stem{$word}} ) {
		
			push @{$by_stem{$stem}}, $word;
		}
	}
	
	#
	# calculate the stem-based count
	#
	
	my %stem_count;
	
	for my $word1 (keys %count) {
	
		# this is to remember what we've
		# counted once already.
		
		my %already_seen;
		
		# first count the word itself
		
		$stem_count{$word1} = $count{$word1};
		
		$already_seen{$word1} = 1;
		
		# now for each of its stems
		
		for my $stem (@{$stem{$word1}}) {
			
			# count each of the words 
			# with which it shares that stem
			
			for my $word2 (@{$by_stem{$stem}}) {
				
				next if $already_seen{$word2};
				
				$stem_count{$word1} += $count{$word2};
				
				$already_seen{$word2} = 1;
			}
		}
	}
	
	for (values %stem_count) { $_ /= $total }
	
	return \%stem_count;
}

sub syn_freq {

	my ($index_ref, $stem_ref, $syn_ref) = @_[0..2];
	
	my %index = %$index_ref;
	my %stem  = %$stem_ref;
	my %syn   = %$syn_ref;
	
	my %by_form;
	
	# create a word->syn index out of %stem, %syn;
	
	for my $form (keys %index) {
	
		my %uniq;
	
		if (defined $stem{$form}) {
		
			for my $stem (@{$stem{$form}}) {
			
				$uniq{$stem} = 1;
				
				if (defined $syn{$stem}) {
				
					for my $syn (@{$syn{$stem}}) {
					
						$uniq{$syn} = 1;
					}
				}
			}
		}
		else {
		
			if (defined $syn{$form}) {
			
				for my $syn (@{$syn{$form}}) {
				
					$uniq{$syn} = 1;
				}
			}
		}
		
		$by_form{$form} = [keys %uniq];
	}
	
	my %syn_freq = %{stem_freq($index_ref, $stem_ref, \%by_form)};
	
	return \%syn_freq;
}
