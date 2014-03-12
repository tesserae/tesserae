#!/usr/bin/env perl

=head1 NAME

score.test.pl - Compare a set of scoring algorithms on the Lucan-Vergil benchmark.

=head1 SYNOPSIS

B<score.test.pl> [OPTIONS]

=head1 DESCRIPTION

Does a Tesserae search using target=lucan.bellum_civile.part.1, source=vergil.aeneid, unit=phrase. Each parallel is scored by each of the scoring modules specified using the --plugin option; if none is specified all available plugins are run. The output is a list of scores for each parallel, along with annotator type and commentary results.

=head1 OPTIONS 

=over

=item B<--plugin> NAME

Use NAME to score each parallel. Must be a Perl module in the plugins directory. To specify more than one plugin, repeat the B<--plugin> flag. If none is specified, all the modules in the plugins dir will be used.

=item B<--quiet>

Don't write progress info to STDERR.

=item B<--help>

Print this message and exit.

=back

In addition, any of the usual options for read_table.pl can be given as well, with the exception of I<source>, I<target>, and I<unit>.

=head1 KNOWN BUGS

=head1 SEE ALSO

I<cgi-bin/read_table.pl>

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is score.test.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Neil Coffee, Chris Forstall, James Gawley.

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
open (OUTPUT, ">scoring.results.tsv") or die "$!";
# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use Parallel;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable qw(nstore retrieve);
use File::Path qw(mkpath rmtree);
use Encode;

binmode STDERR, 'utf8';

#
# set some parameters
#

# source means the alluded-to, older text

my $source ='vergil.aeneid';

# target means the alluding, newer text

my $target ='lucan.bellum_civile.part.1';

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = 'phrase';

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = "stem";

# stopwords is the number of words on the stoplist

my $stopwords = 10;

# stoplist_basis is where we draw our feature
# frequencies from: source, target, or corpus

my $stoplist_basis = "corpus";

# apply the scoring team filter?

my $filter = 0;

# output file

my $file_results = "tesresults";

# session id

my $session = "NA";

# print debugging messages to stderr?

my $quiet = 0;

# maximum distance between matching tokens

my $max_dist = 999;

# metric for measuring distance

my $distance_metric = "freq";

# filter results below a certain score

my $cutoff = 0;

# filter multi-results if passing off to multitext.pl

my $multi_cutoff = 0;                  

# help flag

my $help;

# benchmark data

my $file_bench = catfile($fs{data}, 'bench', 'rec.cache');

# scoring modules to use

my @plugins = qw/Default/;

GetOptions( 
	'feature=s'    => \$feature,
	'stopwords=i'  => \$stopwords, 
	'stbasis=s'    => \$stoplist_basis,
	'binary=s'     => \$file_results,
	'distance=i'   => \$max_dist,
	'dibasis=s'    => \$distance_metric,
	'cutoff=f'     => \$cutoff,
	'quiet'        => \$quiet,
	'help'         => \$help,
	'plugin=s'     => \@plugins
);

#
# print usage info if help flag set
#

if ($help) {

	pod2usage(-verbose => 2);
}

#
# load score plugins
#

for my $plugin (@plugins) {

	print STDERR "trying to load module $plugin...";
	
	$plugin =~ s/[^a-z_].*//i;

	my $mod  = join('::', 'score', 'plugins', $plugin);
	my $path = catfile($fs{script}, 'TessPerl', 'score', 'plugins', $plugin . '.pm');

	if (-s $path) {

		if (eval "require $mod;") {
		
			print STDERR "ok\n";
		}
		else {
		
			print STDERR "failed\n";
		}
	}
	else {

		print STDERR "failed\n";
		warn "Invalid plugin: $plugin";
	}
}

#
# abbreviations of canonical citation refs
#

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# $lang sets the language of input texts
# - necessary for finding the files, since
#   the tables are separate.
# - one day, we'll be able to set the language
#   for the source and target independently
# - choices are "grc" and "la"

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# print all params for debugging

unless ($quiet) {

	print STDERR "target=$target\n";
	print STDERR "source=$source\n";
	print STDERR "lang=$lang{$target};\n";
	print STDERR "feature=$feature\n";
	print STDERR "unit=$unit\n";
	print STDERR "stopwords=$stopwords\n";
	print STDERR "stoplist basis=$stoplist_basis\n";
	print STDERR "max_dist=$max_dist\n";
	print STDERR "distance basis=$distance_metric\n";
	print STDERR "score cutoff=$cutoff\n";
}


#
# calculate feature frequencies
#

# token frequencies from the target text

my $file_freq_target = catfile($fs{data}, 'v3', $lang{$target}, $target, $target . ".freq_score_$feature");

my %freq_target = %{Tesserae::stoplist_hash($file_freq_target)};

# token frequencies from the target text

my $file_freq_source = catfile($fs{data}, 'v3', $lang{$source}, $source, $source . ".freq_score_$feature");

my %freq_source = %{Tesserae::stoplist_hash($file_freq_source)};

#
# basis for stoplist is feature frequency from one or both texts
#

my @stoplist = @{load_stoplist($stoplist_basis, $stopwords)};

unless ($quiet) { print STDERR "stoplist: " . join(",", @stoplist) . "\n"}

#
# if the featureset is synonyms, get the parameters used
# to create the synonym dictionary for debugging purposes
#

my $max_heads = "NA";
my $min_similarity = "NA";

if ( $feature eq "syn" ) { 

	($max_heads, $min_similarity) = @{ retrieve(catfile($fs{data}, "common", "$lang{$target}.syn.cache.param")) };
}


#
# read data from table
#

unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $file_source = catfile($fs{data}, 'v3', $lang{$source}, $source, $source);

my @token_source   = @{ retrieve("$file_source.token") };
my @unit_source    = @{ retrieve("$file_source.$unit") };
my %index_source   = %{ retrieve("$file_source.index_$feature")};

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $file_target = catfile($fs{data}, 'v3', $lang{$target}, $target, $target);

my @token_target   = @{ retrieve("$file_target.token") };
my @unit_target    = @{ retrieve("$file_target.$unit") };
my %index_target   = %{ retrieve("$file_target.index_$feature" ) };


#
#
# this is where we calculated the matches
#
#

# this hash holds information about matching units

my %match_target;
my %match_source;
my %match_score;

#
# consider each key in the source doc
#

unless ($quiet) {

	print STDERR "comparing $target and $source\n";
}

# draw a progress bar

my $pr = ProgressBar->new(scalar(keys %index_source), $quiet);

# start with each key in the source

for my $key (keys %index_source) {

	# advance the progress bar

	$pr->advance();

	# skip key if it doesn't exist in the target doc

	next unless ( defined $index_target{$key} );

	# skip key if it's in the stoplist

	next if ( grep { $_ eq $key } @stoplist);

	# link every occurrence in one text to every one in the other text

	for my $token_id_target ( @{$index_target{$key}} ) {

		my $unit_id_target = $token_target[$token_id_target]{uc($unit) . '_ID'};

		for my $token_id_source ( @{$index_source{$key}} ) {

			my $unit_id_source = $token_source[$token_id_source]{uc($unit) . '_ID'};
			
			$match_target{$unit_id_target}{$unit_id_source}{$token_id_target}{$key} = 1;
			$match_source{$unit_id_target}{$unit_id_source}{$token_id_source}{$key} = 1;
		}
	}
}

#
#
# assign scores
#
#

# how many matches in all?

my $total_matches = 0;

# draw a progress bar

print STDERR "calculating scores\n" unless $quiet;

$pr = ProgressBar->new(scalar(keys %match_target), $quiet);

#
# look at the matches one by one, according to unit id in the target
#

for my $unit_id_target (keys %match_target) {

	# advance the progress bar

	$pr->advance();

	# look at all the source units where the feature occurs
	# sort in numerical order

	for my $unit_id_source (keys %{$match_target{$unit_id_target}}) {
                                     
		# intra-textual matching:
		# 
		# where source and target are the same text, don't match
		# a line with itself
		
		next if ($source eq $target) and ($unit_id_source == $unit_id_target);

		#
		# remove matches having fewer than 2 matching words
		# or matching on fewer than 2 different keys
		#
			
		# check that the target has two matching words
			
		if ( scalar( keys %{$match_target{$unit_id_target}{$unit_id_source}} ) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;
		}
		
		# check that the source has two matching words
	
		if ( scalar( keys %{$match_source{$unit_id_target}{$unit_id_source}} ) < 2) {
	
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}		
	
		# make sure each phrase has at least two different inflected forms
		
		my %seen_forms;	
		
		for my $token_id_target (keys %{$match_target{$unit_id_target}{$unit_id_source}} ) {
						
			$seen_forms{$token_target[$token_id_target]{FORM}}++;
		}
		
		if (scalar(keys %seen_forms) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}	
		
		%seen_forms = ();
		
		for my $token_id_source ( keys %{$match_source{$unit_id_target}{$unit_id_source}} ) {
		
			$seen_forms{$token_source[$token_id_source]{FORM}}++;
		}

		if (scalar(keys %seen_forms) < 2) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}	
				
		#
		# calculate the distance
		# 
				
		my $distance = dist($match_target{$unit_id_target}{$unit_id_source}, $match_source{$unit_id_target}{$unit_id_source}, $distance_metric);
		
		if ($distance > $max_dist) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;
		}
		
		#
		# filter based on scoring team's algorithm
		#
		
		if ($filter and not score_team($match_target{$unit_id_target}{$unit_id_source}, $match_source{$unit_id_target}{$unit_id_source})) {
		
			delete $match_target{$unit_id_target}{$unit_id_source};
			delete $match_source{$unit_id_target}{$unit_id_source};
			next;			
		}
		
		#
		# package up the match for export to modules
		#
				
		my $mat =[
			encapsulate_phrase(
				$match_target{$unit_id_target}{$unit_id_source},
				$unit_target[$unit_id_target],				
				\@token_target,
				\%freq_target
			),
			encapsulate_phrase(
				$match_source{$unit_id_target}{$unit_id_source},
				$unit_source[$unit_id_source],				
				\@token_source,
				\%freq_source
			)
		];
		
		#
		# calculate scores
		#
		
		# score
		
		my @score;
		
		for my $plugin (@plugins) {
			
			push @score, $plugin->score($mat);
		}
												
		# save calculated score, matched words, etc.
		
		$match_score{$unit_id_target}{$unit_id_source} = \@score;
		
		$total_matches++;
	}
}

# benchmark set

print STDERR "reading benchmark set $file_bench\n" unless $quiet;

my $bench = read_bench($file_bench);

# tesserae data as parallel

my $tess = read_tess();

# merge

$bench = merge($tess, $bench);

# print results

export($bench);

#
# subroutines
#

#
# dist : calculate the distance between matching terms
#
#   used in determining match scores
#   and in filtering out bad results

sub dist {

	my ($match_t_ref, $match_s_ref, $metric) = @_;
	
	my %match_target = %$match_t_ref;
	my %match_source = %$match_s_ref;
	
	my @target_id = sort {$a <=> $b} keys %match_target;
	my @source_id = sort {$a <=> $b} keys %match_source;
	
	my $dist = 0;
	
	#
	# distance is calculated by one of the following metrics
	#
	
	# freq: count all words between (and including) the two lowest-frequency 
	# matching words in each phrase.  NB this is the best metric in my opinion.
	
	if ($metric eq "freq") {
	
		# sort target token ids by frequency of the forms
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @target_id; 
			      
		# consider the two lowest;
		# put them in order from left to right
			      
		if ($t[0] > $t[1]) { @t[0,1] = @t[1,0] }
			
		# now go token to token between them, incrementing the distance
		# only if each token is a word.
			
		for ($t[0]..$t[1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
			
		# now do the same in the source phrase
			
		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @source_id; 
		
		if ($s[0] > $s[1]) { @s[0,1] = @s[1,0] }
			
		for ($s[0]..$s[1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# freq_target: as above, but only in the target phrase
	
	elsif ($metric eq "freq_target") {
		
		my @t = sort {$freq_target{$token_target[$a]{FORM}} <=> $freq_target{$token_target[$b]{FORM}}} @target_id; 
			
		if ($t[0] > $t[1]) { @t[0,1] = @t[1,0] }
			
		for ($t[0]..$t[1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
	}
	
	# freq_source: ditto, but source phrase only
	
	elsif ($metric eq "freq_source") {
		
		my @s = sort {$freq_source{$token_source[$a]{FORM}} <=> $freq_source{$token_source[$b]{FORM}}} @source_id; 
		
		if ($s[0] > $s[1]) { @s[0,1] = @s[1,0] }
			
		for ($s[0]..$s[1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span: count all words between (and including) first and last matching words
	
	elsif ($metric eq "span") {
	
		# check all tokens from the first (lowest-id) matching word
		# to the last.  increment distance only if token is of type WORD.
	
		for ($target_id[0]..$target_id[-1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
		
		for ($source_id[0]..$source_id[-1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span_target: as above, but in the target only
	
	elsif ($metric eq "span_target") {
		
		for ($target_id[0]..$target_id[-1]) {
		
		  $dist++ if $token_target[$_]{TYPE} eq 'WORD';
		}
	}
	
	# span_source: ditto, but source only
	
	elsif ($metric eq "span_source") {
		
		for ($source_id[0]..$source_id[-1]) {
		
		  $dist++ if $token_source[$_]{TYPE} eq 'WORD';
		}
	}
		
	return $dist;
}

sub load_stoplist {

	my ($stoplist_basis, $stopwords) = @_[0,1];
	
	my %basis;
	my @stoplist;
	
	if ($stoplist_basis eq "target") {
		
		my $file = catfile($fs{data}, 'v3', $lang{$target}, $target, $target . '.freq_stop_' . $feature);
		
		%basis = %{Tesserae::stoplist_hash($file)};
	}
	
	elsif ($stoplist_basis eq "source") {
		
		my $file = catfile($fs{data}, 'v3', $lang{$source}, $source, $source . '.freq_stop_' . $feature);

		%basis = %{Tesserae::stoplist_hash($file)};
	}
	
	elsif ($stoplist_basis eq "corpus") {

		my $file = catfile($fs{data}, 'common', $lang{$target} . '.' . $feature . '.freq');
		
		%basis = %{Tesserae::stoplist_hash($file)};
	}
	
	elsif ($stoplist_basis eq "both") {
		
		my $file_target = catfile($fs{data}, 'v3', $lang{$target}, $target, $target . '.freq_stop_' . $feature);
		
		%basis = %{Tesserae::stoplist_hash($file_target)};
		
		my $file_source = catfile($fs{data}, 'v3', $lang{$source}, $source, $source . '.freq_stop_' . $feature);
		
		my %basis2 = %{Tesserae::stoplist_hash($file_source)};
		
		for (keys %basis2) {
		
			$basis{$_} = 0 unless defined $basis{$_};
		
			$basis{$_} = ($basis{$_} + $basis2{$_})/2;
		}
	}
		
	@stoplist = sort {$basis{$b} <=> $basis{$a}} keys %basis;
	
	if ($stopwords > 0) {
		
		if ($stopwords > scalar(@stoplist)) { $stopwords = scalar(@stoplist) }
		
		@stoplist = @stoplist[0..$stopwords-1];
	}
	else {
		
		@stoplist = ();
	}

	return \@stoplist;
}


#
# package up a match concisely
#

sub encapsulate_phrase {

	my ($ref_match, $ref_unit, $ref_token, $ref_freq) = @_;
	
	my @token_id = @{$ref_unit->{TOKEN_ID}};
	
	my @match;
	my @token;
	my @freq;
	
	for my $i (@token_id) {
	
		next unless $ref_token->[$i]->{TYPE} eq 'WORD';
		
		push @token, $ref_token->[$i]->{FORM};
		push @freq,  $ref_freq->{$ref_token->[$i]->{FORM}};
				
		if (defined $ref_match->{$i}) {
		
			push @match, $#token;
		}
	}
	
	return (\@token, \@freq, \@match);
}

#
# read benchmark data
#  -- borrowed from append_bench_scores.pl

sub read_bench {

	my $file = shift;
	print STDERR "\nFILE BEING CALLED: $file";

	my @bench = @{retrieve($file)};
	for (0..3) {print STDERR "\n'bench' array position $_: $bench[$_]\n"};

	my $pr = ProgressBar->new(scalar(@bench), $quiet);
	
	for (@bench) {
		
		$pr->advance();
	
		my %rec = %$_;

		my %opt = (
		
		
			target      => 'lucan.bellum_civile.part.1',
			target_loc  => $rec{target_loc},
			target_text => $rec{target_text},
			source      => 'vergil.aeneid',
			source_loc  => $rec{source_loc},
			source_text => $rec{source_text},
#			auth        => $rec{auth},
			type        => $rec{score},
			target_unit => $rec{target_unit},
			source_unit => $rec{source_unit}
		);
			
		$_ = Parallel->new(%opt);
	}
	
	return \@bench;
}

#
# read tesserae data
#

sub read_tess {

	my @tess;
	
	print STDERR "reading tesserae data\n";

	my $pr = ProgressBar->new(scalar(keys %match_score), $quiet);

	for my $unit_id_target (keys %match_score) {
		
		$pr->advance();
	
		for my $unit_id_source (keys %{$match_score{$unit_id_target}}) {
			
			my %opt = (
				
				target      => $target,
				source      => $source,
				target_unit => $unit_id_target,
				source_unit => $unit_id_source,
				score       => $match_score{$unit_id_target}{$unit_id_source}
			);
			
			push @tess, Parallel->new(%opt);
		}
	}
	
	return \@tess;
}

#
# merge the tess results and the bench results,
# combining parallels that refer to the same 
# phrase pairs
#

sub merge {

	my ($ref_a, $ref_b) = @_;
		
	my @a = @$ref_a;
	my @b = @$ref_b;
	
	my %index;
	my @merged;
	
	print STDERR "indexing...\n" unless $quiet;
	
	my $pr = ProgressBar->new(scalar(@a) + scalar(@b), $quiet);
	
	for (@a, @b) {
		
		$pr->advance();
		
		push @{$index{$_->get('target_unit')}{$_->get('source_unit')}}, $_;
	}
	
	print STDERR "merging...\n" unless $quiet;
	
	$pr = ProgressBar->new(scalar(keys %index), $quiet);
	
	for my $unit_id_target (keys %index) {
		
		$pr->advance();
		
		for my $unit_id_source (keys %{$index{$unit_id_target}}) {
		
			my $p = Parallel->new();

			my @to_be_merged = @{$index{$unit_id_target}{$unit_id_source}};
			
			for (@to_be_merged) {
		
				$p->merge($_);
			}

			push @merged, $p;
		}
	}
	
	return \@merged;
}

#
# print score comparison
#

sub export {

	my ($bench_ref, $q_) = @_;
	my @bench = @$bench_ref;
	my $q = ($q_ or $quiet);
	
	print STDERR "exporting records\n" unless $q;
	
	my @fields = qw/target source type auth/;
	
	my @header = (@fields, map {lc} @plugins);
	
	print OUTPUT join("\t", @header) . "\n";
	
	my $pr = ProgressBar->new(scalar(@bench), $q);
	
	for my $p (@bench) {
		
		$pr->advance;
		
		next unless defined $p->get('type');
		
		my $score = $p->get('score'); #These look like previously stored scores. Are they?
		
		unless (defined $score) {
			
			$score = [(undef) x scalar(@plugins)];
		}
		
		my @scores = map {defined $_ ? $_ : 'NA'} @$score;
			for (0..$#scores) {
				if ($scores[$_] eq 'NA') {
					print STDERR "\nUndefined score. Contents of anonymous hash:";
					for my $key (keys (%{$p})) {
						print "\n\t$key \t => \t ${$p}{$key}";
					}
				
				}
			
			}
		print OUTPUT join("\t", 
			$p->dump(
				select => [qw/target source type auth/],
				join   => ';',
				na     => 'NA'
			),
			@scores
		);
				
		print OUTPUT "\n";
	}
}
