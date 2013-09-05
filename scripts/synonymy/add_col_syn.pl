#!/usr/bin/env perl

#
# This is a template for how Tesserae scripts should begin.
#
# Please fill in documentation notes in POD below.
#
# Don't forget to modify the COPYRIGHT section as follows:
#  - name of the script where it says "The Original Code is"
#  - your name(s) where it says "Contributors"
#

=head1 NAME

name.pl	- do something

=head1 SYNOPSIS

name.pl [options] ARG1 [, ARG2, ...]

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<ARG1>

Description of what ARG1 does.

=item B<--option>

Description of what --option does.

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
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable qw/nstore retrieve/;
use File::Copy;
use File::Basename;
use Unicode::Normalize;
use utf8;

# initialize some variables

my $help    = 0;
my $quiet   = 0;
my $feature = 'trans';

my $re_dia   = qr/[\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]/;
my $re_vowel = qr/[αειηουωΑΕΙΗΟΥΩ]/;

# get user options

GetOptions(
	'help'      => \$help,
	'quiet'     => \$quiet,
	'feature=s' => \$feature
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

binmode STDOUT, ':utf8';

#
# get texts to process from command-line args
#

my @files = map { glob } @ARGV;

@files = @{process_file_list(\@files)};

#
# load dictionaries
#

my $file_stem  = catfile($fs{data}, 'common', 'grc.stem.cache');
my $file_trans = catfile($fs{data}, 'common', "grc.$feature.cache");

unless (-e $file_stem) {
	
	die "Can't find stem dictionary $file_stem!";
}
unless (-e $file_trans) {
	
	die "Can't find translation dictionary $file_stem!";
}

print STDERR "Loading stems\n" unless $quiet;
my %stem = %{retrieve($file_stem)};

print STDERR "Loading translations\n" unless $quiet;
my %trans = %{retrieve($file_trans)};

#
# process the files
#

for my $file (@files) {
	
	# take action based on language
	
	my $lang = Tesserae::lang($file);
	
	my $file_base = catfile($fs{data}, 'v3', $lang, $file, $file);

	my $file_index_word  = $file_base . ".index_word";
	my $file_index_stem  = $file_base . ".index_stem";
	my $file_index_trans = $file_base . ".index_$feature";
	my $file_stop_stem   = $file_base . ".freq_stop_stem";
	my $file_stop_trans  = $file_base . ".freq_stop_$feature";
	my $file_score_stem  = $file_base . ".freq_score_stem";
	my $file_score_trans = $file_base . ".freq_score_$feature";

	#
	# if greek, perform translation
	#
	
	if ($lang eq 'grc') {
			
		my $index_word = retrieve($file_index_word);
		my %index_stem = %{retrieve($file_index_stem)};
		my %index_trans;
		
		for my $stem (keys %index_stem) {
			
			my $stem_clean = NFKD($stem);
			$stem_clean =~ s/\d//g;
			$stem_clean =~ s/^(${re_dia}+)(${re_vowel}{2,})/$2/;
			$stem_clean =~ s/^(${re_dia}+)(${re_vowel}{1})/$2$1/;
			$stem_clean =~ s/σ\b/ς/;
			
			for my $trans (@{syns($stem_clean)}) {
				
				push @{$index_trans{$trans}}, @{$index_stem{$stem}};
			}
		}
				
		for my $trans (keys %index_trans) {
			
			$index_trans{$trans} = Tesserae::uniq($index_trans{$trans});			
		}
		
		print STDERR "Writing index $file_index_trans\n" unless $quiet;
		nstore \%index_trans, $file_index_trans;
		
		print STDERR "Writing $file_stop_trans\n" unless $quiet;
		write_freq_stop(\%index_trans, $file_stop_trans);

		print STDERR "Writing $file_score_trans\n" unless $quiet;
		write_freq_score($index_word, $file_score_trans);
	}
	
	#
	# if Latin, just copy the stem index
	#
	
	elsif ($lang eq 'la') {

		print STDERR "Copying $file_index_stem -> $file_index_trans\n" unless $quiet;				
		copy($file_index_stem, $file_index_trans);
		
		print STDERR "Copying $file_stop_stem -> $file_stop_trans\n" unless $quiet;				
		copy($file_stop_stem, $file_stop_trans);
		
		print STDERR "Copying $file_score_stem -> $file_score_trans\n" unless $quiet;				
		copy($file_score_stem, $file_score_trans);
	}
	
	print STDERR "\n" unless $quiet;
}

#
# subroutines
#

sub process_file_list {
	
	my $ref = shift;
	my @list_in = @$ref;
	my @list_out = ();

	for my $file_in (@list_in) {
	
		# large files split into parts are kept in their
		# own subdirectories; if an arg has no .tess extension
		# it may be such a directory

		if (-d $file_in) {

			opendir (DH, $file_in);

			my @parts = (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

			push @list_in, @parts;
					
			closedir (DH);
		
			# move on to the next full text

			next;
		}
	
		my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
		next unless ($suffix eq ".tess");
		
		# get the language for this doc.

		unless ( defined Tesserae::lang($name) ) {

			warn "Can't guess the language of $file_in! Skipping.";
			next;
		}
		
		my $file_stems = catfile($fs{data}, 'v3', Tesserae::lang($name), $name, "$name.index_stem");
		
		unless (-e $file_stems) {
		
			warn "Can't find stem index $file_stems! Skipping.";
			next;
		}
	
		push @list_out, $name;
	}	
	return \@list_out;
}


sub stems {

	my $form = shift;
	
	my @stems;
	
	if (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}

sub syns {
	
	my $stem = shift;
	
	my @syns;
	
	if (defined $trans{$stem}) {

		@syns = @{$trans{$stem}};
	}
	else {
	
		@syns = ($stem);
	}
	
	return Tesserae::uniq(\@syns);
}

sub write_freq_stop {
	
	my ($index_ref, $file) = @_;
	
	my %index = %$index_ref;
	
	my %count;
	
	my $total = 0;
	
	for (keys %index) {
		
		$count{$_} = scalar(@{$index{$_}});
		$total    += $count{$_};
	}
	
	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count{$b} <=> $count{$a}} keys %count) {
		
		print FREQ sprintf("%s\t%i\n", $_, $count{$_});
	}
	
	close FREQ;
}

sub write_freq_score {

	my ($index_ref, $file) = @_;
	
	my %index = %$index_ref;
		
	my %by_feature;
	my %count_by_word;
	my $total;

	# count and index words by feature
	
	for my $word (keys %index) {

		$count_by_word{$word} += scalar(@{$index{$word}});
		
		$total += $count_by_word{$word};
		
		for my $stem (@{stems($word)}) {
			for my $key (@{syns($stem)}) {
		
				push @{$by_feature{$key}}, $word;
			}
		}
	}
	
	for my $key (keys %by_feature) {
	
		$by_feature{$key} = Tesserae::uniq($by_feature{$key});
	}
	
	#
	# calculate the stem-based count
	#
	
	my %count_by_feature;
	
	for my $word1 (keys %count_by_word) {
	
		# this is to remember what we've
		# counted once already.
		
		my %already_seen;
		
		# indexable features
		
		my @indexable;
		
		for my $stem (@{stems($word1)}) {
			for my $trans (@{syns($stem)}) {
				push @indexable, $trans;
			}
		}
		
		@indexable = @{Tesserae::uniq(\@indexable)};
		
		# for each of its indexable features
		
		for my $key (@indexable) {
			
			# count each of the words 
			# with which it shares that stem
			
			for my $word2 (@{$by_feature{$key}}) {
				
				next if $already_seen{$word2};
				
				$count_by_feature{$word1} += $count_by_word{$word2};
				
				$already_seen{$word2} = 1;
			}
		}
	}
	
	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count_by_feature{$b} <=> $count_by_feature{$a}} keys %count_by_feature) { 
	
		print FREQ sprintf("%s\t%i\n", $_, $count_by_feature{$_});
	}
	
	close FREQ;
}
