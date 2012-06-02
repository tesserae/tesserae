# an attempt to implement the method of Jeff Rydberg-Cox
#
# Chris Forstall
# 2012-04-25

use strict;
use warnings;

use Storable qw(nstore retrieve);

use lib '/Users/chris/Sites/tesserae/perl';
use TessSystemVars;

# read the dictionary

# my $file = "tiny.whitaker";
my $file = "$fs_data/common/DICTPAGE.RAW";

my ($dict_ref, $full_def_ref) = whitaker($file);

my %dict  = %$dict_ref;
my %full_def = %$full_def_ref;

# define the max number of headwords for a key
# to be included

my $max_heads = 50;

# the minimum similarity score for a synonym

my $min_similarity = .7;


# index each head by english words

my %index = %{make_index(\%dict)};

# remove stopwords

my $index_ref;

($dict_ref, $index_ref) = remove_stop_words(\%dict, \%index, $max_heads);

%dict = %$dict_ref;
%index = %$index_ref;


# calculate term intersections

my %score = %{intersections(\%index, $max_heads)};


# normalize by number of words in each def

%score = %{normalize(\%score, \%dict)};

# run the benchmark set

# my @benchmark = qw/compes eloquens excellens faux frugifer jocus macer malignitas ostium perfero/;
# export_benchmark(\%score, \%full_def, \@benchmark, 25);

# organize synonyms for each head

my %syn = %{synonyms(\%score, $min_similarity)};


# print list of synonyms

export_list(\%syn, \%full_def, 1);


# save the cache

export_cache(\%syn, "$fs_data/common/la.syn.cache");


# summarize the synonym list

statistics(\%syn, \%dict, $max_heads, $min_similarity, 1);

#
# subroutines
#


# this sub reads the whitaker's words dictionary
# hopefuly this will be superceded by a sub that
# can read the Lewis and Short dictionary.

sub whitaker {

	my $file = shift;
	
	my %dict;
	my %count;
	my %full_def;
	
	open (FH, "<", $file) or die "can't read $file: $!";
	
	print STDERR "reading $file\n";
	
	my $pr = new ProgressBar(-s $file);
	
	while (my $line = <FH>) {
	
		$pr->advance(length($line));
	
		$line =~ /#([a-z]+).+? :: (.*?)[^a-z;]*$/i;
		
		if (defined $1 and $2 ) {
					
			my ($head, $def) = ($1, $2);
		
			if (exists $full_def{$head}) { $full_def{$head} .= "; " }
			
			$full_def{$head} .= $def;
		
			$def = lc($def);
			
			my @words = split(/[^a-z]+/, $def);
			
			for (@words) {
			
				if ($_ ne "") {
					
					$dict{$head}{$_}++;
					$count{$_}++;
				}
			}
		}
	}
	
	close FH;

	return (\%dict, \%full_def);
}

# index each head by english words

sub make_index {

	my $dict_ref = shift;
	my %dict = %$dict_ref;
	
	print STDERR "indexing\n";
	
	my %index;
	
	my $pr = new ProgressBar(scalar(keys %dict));
	
	for my $head (keys %dict) {
		
		$pr->advance();
		
		for my $key ( keys %{$dict{$head}} ) {
			
			$index{$key}{$head} = $dict{$head}{$key};
		}
	}
	
	return \%index;
}

# remove from the dictionary defs any english
# words that appear in too many different defs

sub remove_stop_words {

	my ($dict_ref, $index_ref, $max_heads) = @_;
	
	my %dict  = %$dict_ref;
	my %index = %$index_ref;
	
	# remove entries from the index which have only one headword
	# remove entries from the index which have too many headwords
	
	print STDERR "removing terms appearing in only one dictionary entry\n";
	print STDERR "and terms appearing in more than $max_heads entries\n";
	
	my $pr = ProgressBar->new(scalar(keys %index));
	
	for my $key (keys %index) {
		
		$pr->advance();
	
		if ( scalar(keys %{$index{$key}}) > $max_heads || scalar(keys %{$index{$key}}) == 1 ) {
				
			delete $index{$key};
		}
	}
	
	
	# remove deleted keys from the dictionary entries
	
	print STDERR "removing deleted terms from dictionary entries\n";
	
	$pr = ProgressBar->new(scalar(keys %dict));
	
	for my $head (keys %dict) {
		
		$pr->advance();
	
		for my $key (keys %{$dict{$head}}) {
			
			delete $dict{$head}{$key} unless exists $index{$key};
		}
	}
		
	return (\%dict, \%index);
}

# calculate term intersections

sub intersections {

	my $index_ref = shift;
	my %index = %$index_ref;
	
	print STDERR "calculating intersections\n";

	my %score;
	
	my $pr = new ProgressBar(scalar(keys %index));

	for my $key (keys %index) {
	
		$pr->advance();
		
		for my $head1 (keys %{$index{$key}}) {
			
			for my $head2 (keys %{$index{$key}}) {
				
				$score{ join("~", sort ($head1, $head2)) } += $index{$key}{$head1} + $index{$key}{$head2};
			}
		}
	}
	
	for (values %score) { $_ *= .5 }
		
	return \%score;
}


# normalize by number of words in each def

sub normalize {

	my ($score_ref, $dict_ref) = @_;

	my %score = %$score_ref;
	my %dict = %$dict_ref;
	
	print STDERR "normalizing\n";
	
	my $pr = new ProgressBar(scalar(keys %score));

	for my $bigram (keys %score) {
		
		$pr -> advance();
		
		my ($head1, $head2) = split(/~/, $bigram);
		
		my $total;
		
		for (values %{$dict{$head1}}, values %{$dict{$head2}}) {
		
			$total += $_;
		}
	
		$score{$bigram} = $score{$bigram} / $total;
	}
	
	return \%score;
}


# organize synonyms for each head

sub synonyms {

	my ($score_ref, $min_score) = @_;
	my %score = %$score_ref;

	print STDERR "filtering by similarity; min score=$min_score\n";

	my %syn;
	
	my $pr = new ProgressBar(scalar(keys %score));

	for my $bigram (keys %score) {
		
		$pr->advance();
		
		next if $score{$bigram} < $min_score;
		
		my ($head1, $head2) = split(/~/, $bigram);
		
		push @{$syn{$head1}}, $head2;
		
		next if $head1 eq $head2;
			
		push @{$syn{$head2}}, $head1;
	}
	
	return \%syn;
}


# print list of synonyms

sub export_list {
	
	my ($syn_ref, $full_def_ref, $show_progress) = @_;
	
	my %syn = %$syn_ref;
	my %full_def = %$full_def_ref;
	
	$show_progress = $show_progress || 0;

	print STDERR "exporting synonym list\n";
	
	my $pr = $show_progress ? new ProgressBar(scalar(keys %syn)) : 0;
	
	for my $head (sort keys %syn) {
		
		$pr->advance() if $show_progress;
		
		print "head: $head\n";
		
		print "full_def: $full_def{$head}\n";
	
		for my $syn (sort {score($head, $b) <=> score($head, $a)} sort @{$syn{$head}}) {
			
			my $spacer = "   ";
			
			if ($full_def{$syn} eq $full_def{$head} && score($head, $syn) < 1) { $spacer =" * " }
			
			print sprintf("$spacer%0.2f  % 18s\t%s\n", score($head, $syn), "'$syn'", $full_def{$syn});
		}
		
		print "\n";
	}
}

# export the synonym dictionary for tesserae

sub export_cache {
	
	my ($syn_ref, $file) = @_;
	
	print STDERR "writing $file\n";
	
	nstore $syn_ref, $file;
}

# run the benchmark set

sub export_benchmark {

	my ($score_ref, $full_def_ref, $benchmark_ref, $cutoff) = @_;
	
	my %score = %$score_ref;
	my %full_def = %$full_def_ref;
	my @benchmark = @$benchmark_ref;
	
	my %results;
	
	my $pr = new ProgressBar(scalar(keys %score));
	
	for (keys %score) {
		
		$pr->advance();
	
		my ($head1, $head2) = split(/~/, $_);
		
		if (grep {$_ eq $head1} @benchmark) {
		
			push @{ $results{$head1} }, { SCORE => $score{$_}, TERM => $head2};
		}
		if (grep {$_ eq $head2} @benchmark) {
			
			push @{ $results{$head2} }, { SCORE => $score{$_}, TERM => $head1};
		}
	}
	
	for my $head (keys %results) {
	
		print "$head\n";
		
		my $count = 0;
		
		for (sort {$$b{SCORE} <=> $$a{SCORE}} @{$results{$head}}) {
		
			$count++;
			
			print "$$_{SCORE}\t$$_{TERM}\t$full_def{$$_{TERM}}\n";
			
			last if $count == 25;
		}
		
		print "\n";
	}
}

sub score {

	my ($a, $b) = @_;

	my $score = $score{join("~", sort($a, $b))};

	return defined $score ? $score : 0;
}

# summary output for analysis

sub statistics {

	my ($syn_ref, $dict_ref, $max_heads, $min_similarity, $show_progress) = @_;
	
	my %syn = %$syn_ref;
	my %dict = %$dict_ref;
	
	$show_progress = $show_progress || 0;
	
	print STDERR "calculating statistics\n";
	
	my $all_syns = 0;
	my $max_syns = 0;
	my $max_head = "";
	my $self_match = 0;
	
	my $pr = $show_progress ? new ProgressBar(scalar(keys %syn)) : 0;
	
	for my $head (sort keys %syn) {
		
		my $syns = 0;
		
		$pr->advance() if $show_progress;
			
		for my $syn (sort @{$syn{$head}}) {
			
			$syns++;
			
			if ($syn eq $head) { $self_match = $self_match + 1 }
		}
		
		$all_syns += $syns;
		
		if ($syns > $max_syns) {
			
			$max_syns = $syns;
			$max_head = $head;
		}
	}
	
	print STDERR "file: $file\n";
	print STDERR "total number of headwords: " . scalar(keys %dict) . "\n";
	print STDERR "max headwords per key: $max_heads\n";
	print STDERR "minimum similarity score: $min_similarity\n";
	print STDERR "words that have synonyms: " . scalar(keys %syn) . "\n";
	print STDERR "average number of syns: " . sprintf("%.1f", $all_syns/scalar(keys %syn)) . "\n"; 
	print STDERR "max synonyms: $max_syns ($max_head)\n";
	print STDERR "number of heads that self-match: $self_match\n";
	
}

#
# The following is a new package
#

# how to draw a simple progress bar

package ProgressBar;

sub new {
	my $self = {};
	
	$self->{END} = $_[1];
	
	$self->{COUNT} = 0;
	$self->{PROGRESS} = 0;
	
	print STDERR "0% |" . (" " x 40) . "| 100%";
	
	bless($self);
	return $self;
}

sub advance {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new)	{ $self->{COUNT} += $new }
	else				{ $self->{COUNT}++ }
	
	$self->draw();
}

sub set {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new)	{ $self->{COUNT} = $new }
	else				{ $self->{COUNT} = 0 }
	
	$self->draw();
}

sub draw {

	my $self = shift;
	
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
		
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
		
		my $bars = int($self->{PROGRESS} * 41);
		if ($bars == 41) { $bars-- }
		
		print STDERR "\r" . "0% |" . ("#" x $bars) . (" " x (40 - $bars)) . "| 100%";
	}
	
	if ($self->{COUNT} >= $self->{END}) {
		
		$self->finish();
	}	
}

sub finish {

	print STDERR "\n";
}