#!/usr/bin/env perl

=head1 NAME

build-rec.pl - import benchmark allusions into Tesserae

=head1 SYNOPSIS

build-rec.pl [options]

=head1 DESCRIPTION

This script is supposed to read a set of benchmark, hand-graded allusions
from a text file and correlate the phrases referenced with phrases in our
Tesserae database. 

It's not checking the benchmark set against Tesserae results, it's just 
making sure that we can actually find the phrase pairs in our texts.

The script writes a binary version of the benchmark database, in which
it replaces the original text of the two phrases with the equivalent 
text from Tesserae.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--bench> I<FILE>

Read the benchmark from FILE. Default is 'data/bench/bench4.txt'.

=item B<--cache> I<FILE>

The binary file to write. Default is 'data/bench/rec.cache'.

=item B<--target> I<NAME>

The name of the target text. Default is 'lucan.bellum_civile.part.1'.

=item B<--source> I<NAME>

The name of the target text. Default is 'vergil.aeneid'.

=item B<--delim> STRING

The field delimiter in the text file to be read. Default is tab.

=item B<--check> FLOAT

A similarity threshold between the user-entered text and Tesserae's best
guess at the correct phrase, below which Tesserae will automatically 
check for typos in the locus. Range: 0-1. Default is 0.3.

=item B<--warn> FLOAT

A similarity threshold below which a warning will be printed to the 
terminal. The best match will still be selected, even if the similarity
is 0, but at least you'll know about it. Range: 0-1. Default is 0.18.

=item B<--dump>

For debugging purposes, print the processed benchmark set to the terminal.

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
use Parallel;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Data::Dumper;
use Storable qw(nstore retrieve);
use utf8;

# initialize some variables

my $help  = 0;
my $delim = "\t";
my $quiet = 0;
my $warn  = .18;
my $check = .3;
my $dump  = 0;

# location of the data

my %name = (

	'target' => 'lucan.bellum_civile.part.1',
	'source' => 'vergil.aeneid'
);

my %file = (
	
	bench => catfile($fs{data}, 'bench', 'bench4.txt'),
	cache => catfile($fs{data}, 'bench', 'rec.cache')
);


# get user options

GetOptions(
	'help'     => \$help,
	'quiet'    => \$quiet,
	'delim=s'  => \$delim,
	'cache=s'  => \$file{cache},
	'bench=s'  => \$file{bench},
	'warn=f'   => \$warn,
	'check=f'  => \$check,
	'target=s' => \$name{target},
	'source=s' => \$name{source},
	'dump'     => \$dump
);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

# load the data

my %phrase;
my %loc_phrase;
my %phrase_index;

for my $text (qw/target source/) {

	#
	# load tesserae structures
	#
	
	my $base = catfile($fs{data}, 'v3', Tesserae::lang($name{$text}), $name{$text}, $name{$text});
	
	$phrase{$text} = retrieve("$base.phrase");
	my @line       = @{ retrieve("$base.line") };
	my @token      = @{ retrieve("$base.token") };

	# index the phrases
	# 
	#  for a given line number, an array of phrases which include
	# any part of that line.
	
	for my $phrase_id (0..$#{$phrase{$text}}) {
		
		for my $line_id (@{$phrase{$text}[$phrase_id]{LINE_ID}}) {
			
			push @{$phrase_index{$text}{$line[$line_id]{LOCUS}}}, $phrase_id;
		}
		
		# save the locus elsewhere before we overwrite the phrase
		# in the next loop
		
		$loc_phrase{$text}[$phrase_id] = $phrase{$text}[$phrase_id]{LOCUS};
		$loc_phrase{$text}[$phrase_id] =~ s/-.*//;
		
	}
	

	#
	# simplify the tesserae @phrase arrays to simple arrays of words
	#
		
	# convert word indices to words
	
	for (@{$phrase{$text}}) {
	
		my $phrase = $_;
	
		my @words;
		
		for my $i (@{$$phrase{TOKEN_ID}}) {
			
			next if $token[$i]{TYPE} eq "PUNCT";
			
			my $word = $token[$i]{FORM};
					
			push @words, $word;
		}
				
		$_ = [@words];
	}
}

# load the csv file

my @rec = @{ LoadCSV($file{bench}) };

# confirm that everything worked

for (qw/target source/) {
	
	print STDERR "$name{$_} has " . scalar(@{$phrase{$_}}) . " phrases\n";
}

print STDERR "the csv file contains " . scalar(@rec) . " records\n\n";


#
# match up each record with a parsed phrase 
#

print STDERR "aligning records\n\n";

REC: for my $rec_index (0..$#rec) {	

	for my $text (qw/source target/) {
			
		# get the locus and the corresponding index
		# for the array containing the text
			
		my $loc = $rec[$rec_index]->get($text . '_loc');
		my $lang = Tesserae::lang($name{$text});
			
		if (! defined $phrase_index{$text}{$loc} ) { 
					
			die "$rec_index : $text $loc has no entry in phrase_index" 
		}
		
		my @phrase_index = @{$phrase_index{$text}{$loc}};
			
		# get the phrase from the CSV file
	
	 	my $search = $rec[$rec_index]->get($text . '_text');
	
		# do the search
		
		my ($decided, $max, $debug_string) = Align($lang, $search, $text, \@phrase_index);
				
		# if the results are really bad, check for a missing zero in the line number
		
		if ($max < $check) {
			
			if (defined $phrase_index{$text}{$loc . '0'}) {
				
				# print STDERR "checking lost trailing zeros\n";
				
				push @phrase_index, @{$phrase_index{$text}{$loc . '0'}};
				
				if (defined $phrase_index{$text}{$loc . '00'}) { 
					
					push @phrase_index, @{$phrase_index{$text}{$loc . '00'}} ;
				}
				
				($decided, $max, $debug_string) = Align($lang, $search, $text, \@phrase_index);
			}
		}
		
		# check for total failure
		
		if (not defined $debug_string) {
			
			$debug_string = "[empty search]";
		}	
		
		if ($max <= $warn) {
		
			print STDERR "$rec_index : $text $loc : $debug_string\n";
			print STDERR "  $max\t$decided\t$loc_phrase{$text}[$decided]\t" . join(" ", @{$phrase{$text}[$decided]}) . "\n";
			print STDERR "\n";
		}
		
#		print STDERR "decided $decided by $max\n";
				
		$rec[$rec_index]->set($text . '_text', join(" ", @{$phrase{$text}[$decided]}));
		$rec[$rec_index]->set($text . '_unit', $decided);
	}
}

print STDERR "writing " . scalar(@rec) . " records to $file{cache}\n";

nstore \@rec, $file{cache};

if ($dump) {

	dump_debug(\@rec);
}

#
# this subroutine reads the CSV file containing hand-graded allusions
#

sub LoadCSV {
		
	my $file = shift;
	
	my @rec;

	open (FH, "<:utf8", $file) or die "can't open $file: $!";

	print STDERR "reading $file\n";
	
	# skip the header
	
	<FH>;
	
	while (my $line = <FH>) {
		
		chomp $line;
		
		my @field = split(/$delim/, $line);
				
		for (@field) {
			
			s/^"(.*)"$/$1/;
		}
		
		push @rec, Parallel->new(
			target      => $name{target},
			target_loc  => join('.', @field[0,1]),
			target_text => $field[2],
			source      => $name{source},
			source_loc  => join('.', @field[3,4]),
			source_text => $field[5],
			type        => $field[6],
			auth        => (defined $field[7] ? [split(/;/, $field[7])] : $field[7])
		);
	}
	
	return \@rec;
	
	close FH;
}

# this sub takes two strings and an array ref
# the first string is a phrase
# the second string is the text to search
# the array ref is a list of indices to test

sub Align {
	
	my ($lang, $search, $text, $pi_ref) = @_;

	$search = lc($search);
	my @search = split(/$non_word{$lang}/, $search);
	@search = Tesserae::standardize($lang, @search);

	my @phrase_index = @$pi_ref;

	# check for empty search
	
	if ($#search < 0) {
		
		return ($phrase_index[0], 0, undef);
	}

	# this holds the max consecutive words matched

	my $max = 0;
	my $decided = $phrase_index[0];
	my $debug_string = join(" ", @search);

	# try to match words
	# for each of the phrases beginning on this line

	for my $pi (sort @phrase_index) {
	
		my @target = @{$phrase{$text}[$pi]};
	
		my $matched = 0;
		
		my @temp;
	
		# now see how much of the phrase we can match
	
		for my $s (@search) {
			
			if ( grep { $_ eq $s } @target ) { 
				
				$matched++;
				
				push @temp, uc($s);
			}
			else { push @temp, $s }
		}
		
		$matched = sprintf("%.2f", $matched/scalar(@search));
	
		if ($matched > $max)  {
			 
			$max = $matched; 
			$decided = $pi;
			$debug_string = join(" ", @temp);
		}
	}
		
	return ($decided, $max, $debug_string);
}

sub dump_debug {

	my $ref = shift;
	my @rec = @$ref;
	
	print STDERR "All records:\n";
	
	for my $r (@rec) {
		
		print STDERR join("\t", $r->dump(na=>'NA', lab=>1)) . "\n";
	}
}