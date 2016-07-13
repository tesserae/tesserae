#!/usr/bin/env perl

=head1 NAME

batch.multi.pl - Perform a series of Tesserae searches and a following series of multitext searches.

=head1 SYNOPSIS

B<batch.multi.pl> B<--config> I<configuration_file> B<--binary> I<results_folder> [OPTIONS]

=head1 DESCRIPTION
Performs a 'batch' of searches with the intent of using the multitext tool to eliminate other possible contemporary sources for an intertext.

This script requires a configuration file (see '--config' below). 

This search techniques requires extremely large amounts of both hard disk space and RAM.

Final results include an array of multitext Tesserae results plus 'summary' files describing the rate of intertextuality between the authors in the configuration file.

--config file format: 
 [source]
 cicero.orator
 caesar.de_bello_gallico
 your.text_here


 [target]
 lucan.bellum_civile
 tacitus.annales.part.1
 
 [end]


Command-line example: 

% scripts/batch/batch.multi.pl --config cicero_and_caesar_versus_lucan_and_tacitus.txt \	
                        --binary multitext_results

=head1 OPTIONS 

=over

=item B<--unit> line|phrase

I<unit> specifies the textual units to be compared.  Choices currently are B<line> (the default) which compares verse lines or B<phrase>, which compares grammatical phrases.  For now we assume that the punctuation marks [.;:?] delimit phrases.

=item B<--feature> word|stem|syn 

This specifies the features set to match against.  B<word> only allows matches on forms that are identical. B<stem> (the default), allows matches on any inflected form of the same stem. B<syn> matches not only forms of the same headword but also other headwords taken to be related in meaning.  B<stem> and B<syn> only work if the appropriate dictionaries are installed; B<syn> won't work on Greek or English.

=item B<--freq_basis> texts|corpus

This specifies the basis of the frequency metric used by the scoring algorithm.  B<text> (the default), retrieves the frequency of a given stem in the target and source text B<corpus> forces the system to use corpus-wide frequency statistics.

=item B<--score> word|stem|feature 

Also affects which frequency statistics are used by the scoring algorithm.  B<word> uses frequency stats for the appearance of the exact string of characters (in either the corpus or the individual text, as determined by --freqbasis). B<stem> uses stats which are based on the number of times any inflected form of a word appeared in the text (or corpus; see --freqbasis). B<feature> (the default), invokes a lookup table which coordinates feature types with their ideal score bases. NB: it is critical to use this setting when scoring cross-language matches.

=item B<--stop> I<stoplist_size>

I<stoplist_size> is the number of stop words (stems, etc.) to use.  Matches on any of these are excluded from results.  The stop list is calculated by ordering all the features (see above) in the stoplist basis (see below) by frequency and taking the top I<N>, where I<N>=I<stoplist_size>.  The default is 10.

=item B<--stbasis> corpus|target|source|both

Stoplist basis is a string indicating the source for the ranked list of features from which the stoplist is taken.  B<corpus> (the default) derives the stoplist from the entire corpus; B<source>, uses only the source; B<target>, only the target; and B<both> uses the source and target but nothing else.

=item B<--dist> I<max_dist>

This sets the maximum distance between matching words.  For two units (one in the source and one in the target) to be considered a match, each must have at least two words common to the other (regardless of the feature on which they matched).  It's generally true that in good allusions these words are close together in both units.  Setting the maximum distance to I<N> means that matches where either unit's matching words are more than I<N> words apart will be excluded. The default distance is 999, which is presumably equivalent to setting no limit. Note that adjacent words are considered to have a distance of 1, words separated by an intervening word have a distance of 2, and so on.

=item B<--dibasis> span|span-target|span-source|freq|freq-target|freq-source

Distance basis is a string indicating the way to calculate the distance between matching words in a parallel (matching pair of units).  B<span> adds together the distance in words between the two farthest-apart words in each phrase.  Related to this are B<span-target> which uses the distance between the two farthest-apart words in the target unit only, and B<span-source> which uses the two farthest-apart words in the source unit.  A (probably) better basis is B<freq>, which uses the distance between the two words with the lowest frequencies (in their own text only), adding the frequency-based distances of the target and source units together.  As for B<span>, you can select the frequency-based distance in only one text with B<freq-target> or B<freq-source>.  The default is B<freq>.

=item B<--cutoff> I<score_cutoff>

Each match found by Tesserae is given a score.  Setting a cutoff will cause any match with a score less than this to be dropped from the results.  Default is 0 (presumably equivalent to no cutoff).

=item B<--binary> I<name>

This is the name to be given to the session. Tesserae will create a new directory with this name and save there the Storable binaries containing your results.  The default is I<tesresults>.

=item B<--multionly>

Skip the initial series of Tesserae searches and move on to the multitext comparisons. Inform user how many multitext comparisons remain. See 'KNOWN BUGS.'

=item B<--countonly>

Skip all searches and examine multitext results files only. Inform user how many multitext comparisons remain undone. See 'KNOWN BUGS.'

Requires --multionly.

=item B<--help>

Print this message and exit.

=back

The values of all these options should be printed to STDERR when you run the script from the command-line, and should also be saved with the results.

=head1 KNOWN BUGS

This script is known to fail due to hardware limitations. When this happens, it is possible to re-run selected stages of the script. See --multionly and --countonly

=head1 SEE ALSO

I<scripts/read_table.pl>
I<scripts/multitext.pl>
I<scripts/read_multi.pl>

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is read_table.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): James Gawley, Caitlin Diddams, Chris Forstall.

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

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
use Data::Dumper;

# load additional modules necessary for this script

use utf8;
use File::Path qw(mkpath rmtree);
use File::Basename;
use File::Copy;
use Storable qw(nstore retrieve);
use Encode;


# initialize variables





my $lang = 'la';

my $max_processes = 1;

my $help = 0;

my $config;

my $verbose = 2;

# initialize search options

my $source;

my $target;

my $unit = 'phrase';

my $feature = 'stem';

my $stopwords = '10';

my $freq_basis = 'text';

my $stoplist_basis = 'target';

my $max_dist = 999;

my $distance_metric = 'freq';

my $cutoff = 0;

my $batch_folder = 'batch_results';

my $multionly;

my $countonly;

#
# command line options
#

GetOptions( 
	"unit=s"		=> \$unit,
	"feature=s"		=> \$feature,
	"stopword=i"	=> \$stopwords,
	"freq_basis=s"	=> \$freq_basis,
	"st_basis=s"	=> \$stoplist_basis,
	"binary=s"		=> \$batch_folder,
	"distance=i"	=> \$max_dist,
	"dibasis=s"		=> \$distance_metric,
	"cutoff=f"		=> \$cutoff,
	"lang=s"        => \$lang,
	"config=s"		=> \$config,
	"multionly"		=> \$multionly,
	"countonly"		=> \$countonly,
	"help"          => \$help
	);

# print usage if the user needs help
if ($help) {

	pod2usage(-verbose => 2);
}
use Parallel::ForkManager;

#open the config file for this batch search supplied by user
 
open (my $c, "$config") or die $!;


#get a list of all the existing texts in the relevant language

my @textlist = Tesserae::get_textlist($lang);

@textlist = @{$textlist[0]};

# map the array of text names to a hash for easy checking

my %texts = map { $_ => 1 } @textlist;

my @array;

my @targetarray;

# read the config file, grab everything under 'source', and check against the text list.


while (<$c>) {
	chomp;

	if (/^\[source\]/../^\[target\]/) {

		if ($texts{$_}) {
			
			push (@array, $_);
		
		}
	
	};
	
	if (/^\[target\]/../^\[end\]/) {
	
		if ($texts{$_}) {
			
			push (@targetarray, $_);
		
		}
	
	};	
	
		
}

#open a directory for the batch run metadata

my $batchdir = catdir($batch_folder);

opendir(BATCHDIR, $batchdir);

#open a dir to hold all the 'tesresults' style directories

my $directory = catdir($batch_folder, 'working');


#loop through all target vs. source combos

my %target_source;

my %source_target;

unless ($multionly) {

my $pm = Parallel::ForkManager->new(12);

foreach my $source (@array) {

	foreach my $target (@targetarray) {
		
		# Forks and returns the pid for the child:
    	my $pid = $pm->start and next;

		# avoid searching the same combination twice

		if (grep( /^$source$/, @{$target_source{$target}}) | grep( /^$target$/, @{$source_target{$source}}) | $target eq $source) {
			
			next;
		
		}
		
		# build read_table command and execute
		
		my $results = catdir($batch_folder, 'working', "$source.$target");

		
		my $read_table = catfile($fs{cgi}, 'read_table.pl');

		my $search_command = "perl $read_table --source $source --target $target  --unit $unit  --feature $feature  --stopwords $stopwords  --freq_basis $freq_basis  --stbasis $stoplist_basis  --binary $results  --distance $max_dist  --dibasis $distance_metric  --cutoff $cutoff";
		
		exec_run($search_command);
		
		# record search to avoid replication
		
		
		push @{$target_source{$target}} , $source;
		
		push @{$source_target{$source}} , $target;
		
		$pm->finish; # Terminates the child process
	
	}

}



}





my $p = Parallel::ForkManager->new(3);


opendir(DH, $directory);

# access the batch results data

# first find all the folders where batch results live


my @directories = grep {/^[^.]/} readdir(DH);


# grab the scripts to run from bash (search multitext and create multitext results)

my $multiscript = catfile($fs{cgi}, 'multitext.pl');

my $readscript = catfile($fs{cgi}, 'read_multi.pl');

if ($multionly) {

	my $dircount = 0;

	for (0..$#directories){
	
		
	
		my $directory = catdir($batch_folder, 'working', $directories[$_]);

		my $resultsdir = catfile ($directory, 'multi_results.tsv');
	
		unless (-s $resultsdir) {		
	
			$dircount++;
	
		}
	}
	
	print "\nAbout to multitext $dircount directories without existing tsv files.";
	
	my $useless = <STDIN>;
	
	
}

# loop through 'tesresults' style folders in the batch_results folder
unless ($countonly) {

for (0..$#directories) {

 #   my $pid = $p->start and next;	

	# open the current dir of results
	
	my $directory = catdir($batch_folder, 'working', $directories[$_]);

	my $resultsdir = catfile ($directory, 'multi_results.tsv');
	
	next if -s $resultsdir;		

	# create a list of works to search against.

	my $listfile = catfile($directory, '.multi.list');
	
	open (MULTILIST, ">$listfile") or die $!;
	
	# select only those authors different from the source author
	
	my $metafile = catfile($directory, 'match.meta');
	
	my %meta = %{ retrieve($metafile)};

	
	my $source_author = $meta{SOURCE};
	
	$source_author =~ /(\w+)\./;
	
	$source_author = $1;
	
	my @multi;
	
	foreach my $work (@array) {
	
		if (index ($work, $source_author)) {
		
			push (@multi, $work);
		
		}
	
	}

	print MULTILIST join ("\n", @multi);
	
	
		
	# build the commands to send to bash

	my $multicommand = "perl $multiscript $directory --list --parallel 3";

	my $readcommand = "perl $readscript --export tab $directory > $resultsdir";
	
	# execute commands (search multi and save results file)

	exec_run($multicommand);
	
	exec_run($readcommand);
	
	my $multidir = catdir ($directory, 'multi');
	
	exec_run("rm -r $multidir");

#	$p->finish; # Terminates the child process	
	
}
}

# Create a file with counts of unique results by source author.

my $resfile = catfile($batchdir, "unique_results_count.tsv");

open (COUNT, ">$resfile") or die $!;

print COUNT "SOURCE_AUTH\tSOURCE_TXT\tTARGET_AUTH\tTARGET_TXT\tPHRASES\tUNIQUE\tNORMALIZED\n";

my %summary;

for (0..$#directories) {
	print "Indexing $directories[$_]\n";
	
	# open the TSV file of multitext results.

	my $multi_file = catdir($batch_folder, 'working', $directories[$_], 'multi_results.tsv');
	
	next unless -s $multi_file;	
	
	open (my $t, $multi_file) or next;
	
	# this is a hack; it should be replaced by opening match.meta for this folder.
	
	my $target_auth = "";
	
	my $target_text = "";
	
	my $source_auth = "";
	
	my $source_text = "";
	
	my @other_authors = ();
	
	my $count;
#			exec_run("tput bel");
	while (<$t>) {
	
		if ($_ =~ /\#\starget\s+=\s(\w+)\.(\w+)/) {
		
			$target_auth = $1;
			
			$target_text = $2;
		
		}

		if ($_ =~ /\#\ssource\s+=\s(\w+)\.(\w+)/) {
		
			$source_auth = $1;
			
			$source_text = $2;
		
		}

		# figure out which multitext result columns don't contain the source author
		
		if ($_ =~ /RESULT/) {
		
			my @line = split ("\t", $_);
			

			
			for my $col (9..$#line) {
			
				unless ($line[$col] =~ /$source_auth/) {
				
					push (@other_authors, $col);
				
				}
			
			}
		
		
		}
		

		# count unique results
				
		if ($_ =~ /^\d/) {	
			
			my $countit = 0;
			
			my @line = split ("\t", $_);
			

			
			

			
			foreach my $col (@other_authors) {
			
				unless ($line[$col] =~ /\d/) {
				
					$countit++;

				}
			
			}
			
			# only include if all columns from the other authors are blank
		
			if ($countit == scalar @other_authors) {
			
				$count++;
				

			
			}
		
		}
		

	
	}

	# calculate number of opportunities to make a match
		
	my $targ_unit = catfile($fs{data}, 'v3', $lang, "$target_auth.$target_text", "$target_auth.$target_text.$unit");
		
	my @targ_array = @{ retrieve($targ_unit)};
		
	my $source_unit = catfile($fs{data}, 'v3', $lang, "$source_auth.$source_text", "$source_auth.$source_text.$unit");
		
	my @source_array = @{ retrieve($source_unit)};

	my $norm = ($#targ_array + 1) * ($#source_array +1);
	
	my $norm_score = $count / $norm;
	
	print COUNT "$source_auth\t$source_text\t$target_auth\t$target_text\t$norm\t$count\t$norm_score\n";
	
	#This dereferences a two-element array, inside an anonymous hash keyed by source author, located inside the %summary hash, which is keyed by target author.
	
	${${$summary{$target_auth}}{$source_auth}}[0] += $norm;
	
	${${$summary{$target_auth}}{$source_auth}}[1] += $count;
	
	close $t;
	
}

close COUNT;

my $sumfile = catfile($batchdir, "summary.csv");

open (SUM, ">$sumfile") or die $!;

print SUM "SOURCE_AUTH,TARGET_AUTH,PHRASES,UNIQUE,NORMALIZED\n";

foreach my $target_author (keys %summary) {
	
	foreach my $source_author (keys %{$summary{$target_author}}) {
	
		my $phrases = ${${$summary{$target_author}}{$source_author}}[0];
		
		my $count = ${${$summary{$target_author}}{$source_author}}[1];
		
		print SUM "$source_author,$target_author,$phrases,$count," . ($count / $phrases) . "\n";		
	
	}

}










#
# execute a run, return benchmark data
#

sub exec_run {

	my $cmd = shift;
	
	print STDERR $cmd . "\n" if $verbose > 1;
	
	my $bmtext = `$cmd`;
	
	$bmtext =~ /total>>(\d+)/;
	
	return $1;
}

