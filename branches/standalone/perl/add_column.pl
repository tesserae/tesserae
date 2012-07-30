# add_column.pl
#
# add a new text to the big table
# --identical form matching
#
# The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at doc/LICENSE.txt or http://tesserae.caset.buffalo.edu/license.txt.
# 
# Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations under the License.
# 
# The Original Code is this file, add_column.pl.
# 
# The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.
# 
# Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.
# 
# Contributor(s): Neil Coffee, Chris Forstall, James Gawley, J.-P. Koenig, Roelant Ossewaarde, and Shakthi Poornima.
# 
# Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

use strict;
use warnings; 

use FindBin qw($Bin);

use lib $Bin;
use TessSystemVars;
use EasyProgressBar;

use File::Path qw(mkpath rmtree);
use File::Basename;
use Cwd;
use Storable qw(nstore retrieve);
use Getopt::Long;

# 
# some parameters
# 

my %abbr;
my $file_abbr = "$fs_data/common/abbr";
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

my %lang;
my $file_lang = "$fs_data/common/lang";

if (-s $file_lang )	{ %lang = %{retrieve($file_lang)} }

#
# allow language for individual files to be given on the
# command line, using flags --la or --grc
#

my $lang;

GetOptions("lang=s" => \$lang);

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV) {

	# the header for the column will be the filename 
	# minus the path and .tess extension
	
	next unless -f $file_in && $file_in =~ /\.tess$/;

	my ($name, $directories, $suffix) = fileparse($file_in, '.tess');

	print STDERR "$name:$directories:$suffix\n";

	# get the language for this doc.  try:
	# 1. user specified at cmd line
	# 2. cached from a previous successful parse
	# 3. in the path to the file, as subdir of texts/
	# - then give up

	print STDERR "$directories\n$fs_text\n";

	if (defined $lang) {
	}	
	elsif ( defined $lang{$name} ) {

		$lang = $lang{$name};
	}
	elsif (Cwd::abs_path($file_in) =~ /$fs_text\/(.*)\//) {
		
		$lang = $1;
	}
	else {
		
		print STDERR "Can't guess the language of $file_in!\n";
		$lang = "unknown";
	}
	
	#
	# assume unknown lang is like english
	#
	
	unless (defined $is_word{$lang})  { $is_word{$lang}  = $is_word{en} }
	unless (defined $non_word{$lang}) { $non_word{$lang} = $non_word{en} }
	
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
	
	my $file_stem = "$fs_data/common/$lang.stem.cache";
	my $file_syn  = "$fs_data/common/$lang.syn.cache";
	
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

	# parse and index:
	#
	# - every word will get a serial id
	# - every line is a list of words
	# - every phrase is a list of words

	print STDERR "reading text: $file_in\n";

	# open the input text

	open (TEXT, "<:utf8", $file_in) or die("Can't open file ".$file_in);

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
	#  - add a LOCUS tag with range of lines in human-readable form
	#
		
	for my $phrase_id (0..$#phrase) { 
		
		$phrase[$phrase_id]{LINE_ID} = [sort {$a <=> $b} keys %{$phrase[$phrase_id]{LINE_ID}} ];

		# if there's a range, make it easy to read;
			
		my $loc_1 = $line[$phrase[$phrase_id]{LINE_ID}[0]]{LOCUS};
		my $loc_2 = $line[$phrase[$phrase_id]{LINE_ID}[-1]]{LOCUS};
			
		my $range;
		
		if ($loc_2 ne $loc_1) {
		
			my $base_1 = $loc_1;
			my $base_2 = $loc_2;
		
			$base_1 =~ s/(.+\.).+/$1/;
			$base_2 =~ s/(.+\.).+/$1/;
		
			if ($base_1 eq $base_2) {
			
				for (0..length($loc_1)) {
				
					if (substr($loc_1, $_, 1) ne substr($loc_2, $_, 1)) {
						
						$loc_2 = substr($loc_2, $_);
						last;
					}
				}
			}	
				
			$range = "$loc_1-$loc_2";
		}
		else {
			
			 $range = $loc_1;
		}
		
		$phrase[$phrase_id]{LOCUS} = $range;
	}
		
		
	#
	# save the data
	#
	
	# make sure the directory exists
	
	my $path_data = "$fs_data/v3/$lang/$name";
	
	unless (-d $path_data ) { mkpath($path_data) }

	my $file_out = "$path_data/$name";

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
	
	unless ($no_stems) {

		print "writing $file_out.index_stem\n";
		nstore \%index_stem, "$file_out.index_stem";
		
		print "writing $file_out.freq_stem\n";
		nstore freq_from_index(\%index_stem), "$file_out.freq_stem";
	}
	unless ($no_syns) {

		print "writing $file_out.index_syn\n";
		nstore \%index_syn, "$file_out.index_syn";
		
		print "writing $file_out.freq_syn\n";
		nstore freq_from_index(\%index_syn), "$file_out.freq_syn";
	}

	# add this ref to the database of abbreviations

	unless (defined $abbr{$name}) {
	
		$abbr{$name} = (sort { $ref{$b} <=> $ref{$a} } keys %ref)[0];
		nstore \%abbr, $file_abbr;
	}

	# save the language designation for this file

	unless (defined $lang{$name}) {
	
		$lang{$name} = $lang;
		nstore \%lang, $file_lang;
	}
}


#

sub print_rec {

	my $href = shift;
	
	my %rec = %$href;
	
	my $string = "";
	
	for my $key (keys %rec) {
	
		my $value;
		
		if (ref($rec{$key}) eq "") {
			
			$value = $rec{$key};
		}
		
		if (ref($rec{$key}) eq "SCALAR") {
			
			$value = ${$rec{$key}};
		}
		
		if (ref($rec{$key}) eq "ARRAY") {
		
			$value = '(' . join(", ", @{$rec{$key}}) . ')';
		}
		
		if (ref($rec{$key}) eq "HASH") {
		
			my @pairs;
			
			for (keys %{$rec{$key}}) {
			
				push @pairs, "$_ => $rec{$key}{$_}";
			}
			
			$value = '(' . join(", ", @pairs) . ')';
		}
		
 		$string .= "$key: $value\n";
	}
	
	return $string;
}

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