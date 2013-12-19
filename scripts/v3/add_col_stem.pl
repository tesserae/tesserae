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

add_col_stem.pl - index additional feature sets

=head1 SYNOPSIS

add_col_stem.pl [options] FILES

=head1 DESCRIPTION

Indexes additional feature sets for texts in the Tesserae corpus. To be run after
add_column.pl. By default, it adds the stem featureset for every text specified;
alternate featuresets can be selected using the --feature option.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<FILES>

The list of files to index.

=item B<--feature> I<FEATURE>

Index the I<FEATURE> feature set. Multiple feature sets can be selected by using
the flag more than once. The default is 'stem'. If a feature set other than 'stem'
is specified, then 'stem' must also be specified explicitly if you want to create 
a stem index too.

=item B<--use-lingua-stem>

Use the Porter stemmer in CPAN package Lingua::Stem to stem tokens, rather than
a built-in Tesserae stem dictionary.

=item B<--parallel> I<N>

Allow I<N> processes to run in parallel. Requires Parallel::ForkManager.

=item B<--quiet>

Suppress (at least some) debugging and progress messages.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is add_col_stem.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

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

use Storable qw/nstore retrieve/;
use File::Copy;
use File::Basename;
use Unicode::Normalize;
use utf8;

# optional modules

my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

# initialize some variables

my $help    = 0;
my $quiet   = 0;
my $use_lingua_stem = 0;
my @feature;

#
# These are for parallel processing
#

my $max_processes = 0;
my $pm;

# get user options

GetOptions(
	'help'            => \$help,
	'quiet'           => \$quiet,
	'feature=s'       => \@feature,
	'use-lingua-stem' => \$use_lingua_stem,
	'parallel=i'      => \$max_processes
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

binmode STDOUT, ':utf8';

# default feature set is stem

@feature = ('stem') unless @feature;

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

#
# initialize stemmer
#

if ($use_lingua_stem) {

	Tesserae::initialize_lingua_stem();
}

#
# get texts to process from command-line args
#

my @files = map { glob } @ARGV;

@files = @{check_feature_dep(Tesserae::process_file_list(\@files))};

#
# process the files
#

for my $file (@files) {
	
	# fork
	
	if ($max_processes) {
	
		$pm->start and next;
	}
	
	my $lang = Tesserae::lang($file);
		
	my $file_index_word = catfile($fs{data}, 'v3', $lang, $file, "$file.index_word");
	
	my %index_word = %{retrieve($file_index_word)};
	
	for my $feature (@feature) {
		
		my %index_feat;
	
		for my $form (keys %index_word) {
			
			for my $feat (@{Tesserae::feat($lang, $feature, $form)}) {
				
				push @{$index_feat{$feat}}, @{$index_word{$form}};
			}
		}
	
		for my $feat (keys %index_feat) {
		
			$index_feat{$feat} = Tesserae::uniq($index_feat{$feat});
		}

		my $file_index = catfile($fs{data}, 'v3', $lang, $file, "$file.index_$feature");
	
		print STDERR "Writing index $file_index\n" unless $quiet;
		nstore \%index_feat, $file_index;
		
		Tesserae::write_freq_stop($file, $feature, \%index_feat, $quiet);
		Tesserae::write_freq_score($file, $feature, \%index_word, $quiet);
	}
	
	$pm->finish if $max_processes;	
}

$pm->wait_all_children if $max_processes;

#
# subroutines
#

sub check_feature_dep {

	my $ref = shift;

	my @file = @$ref;	
	my %file_ok = map {($_, 1)} @file;
	
	for my $feature (@feature) {
	
		next unless defined $Tesserae::feature_dep{$feature};

		for my $file (@file) {

			my $file_dep = catfile($fs{data}, 'v3', Tesserae::lang($file), $file, "$file.index_$Tesserae::feature_dep{$feature}");

			unless (-e $file_dep) {
		
				$file_ok{$file} = 0
			}
		}
	}
	
	return [grep { $file_ok{$_} } @file];
}

