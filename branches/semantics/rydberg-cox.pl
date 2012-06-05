# an attempt to implement the method of Jeff Rydberg-Cox
#
# Chris Forstall
# 2012-04-25

use strict;
use warnings;

use Getopt::Long;
use Graph;
use Storable qw(nstore retrieve);

use lib '/Users/chris/tesserae/perl';
use TessSystemVars;


# define the max number of headwords for a key
# to be included

my $max_heads = 50;

# the minimum similarity score for a synonym

my $min_similarity = .7;

# draw progress bars?

my $quiet = 0;

# the dictionary to parse

my $file_dict  = "$fs_data/common/DICTPAGE.RAW";

# the cache file to write

my $file_cache = "none";

# text file to write groups to

my $file_group = "none";

# html file to write thesaurus to

my $file_html = "none";

# text file to write thesaurus to

my $file_text = "none";

# file to write histogram data to

my $file_hist = "none";


# set parameters from cmd line options if given 

GetOptions ('max_heads=i' => \$max_heads, 
				'min_similarity=f' => \$min_similarity, 
				'dictionary=s' => \$file_dict, 
				'cache:s' => \$file_cache,
				'html:s' => \$file_html,
				'text:s' => \$file_text,
				'groups:s' => \$file_group,
				'hist:s' => \$file_hist,
				'quiet' => $quiet);
				
if ($file_cache eq "") { $file_cache = "$fs_data/common/la.syn.cache" }

#
# global variables
# 

my %dict;
my %full_def;
my %index;
my %score;
my %syn;
my $graph = Graph::Undirected->new();
my @syn_group;

#
# read the dictionary
#

read_dictionary($file_dict);

#
# index each head by english words
#

make_index();

#
# remove stopwords
#

remove_stop_words($max_heads);

#
# calculate term intersections
#

intersections();

#
# normalize by number of words in each def
#

normalize();

#
# run the benchmark set
#
# my @benchmark = qw/compes eloquens excellens faux frugifer jocus macer malignitas ostium perfero/;
# export_benchmark(@benchmark);

#
# organize synonyms for each head
#

synonyms($min_similarity);


#
# print list of synonyms as text
#

if ($file_text ne "none") {
	
	export_list($file_text);
}

#
# export list as html
#

if ($file_html ne "none") {

	export_list_html($file_html);
}

#
# export syn group ids as plain text
#

if ($file_group ne "none") {
	
	export_syn_groups($file_group);
}

#
# save the cache
#
if ($file_cache ne "none") {

	 export_cache($file_cache);
}

#
# summarize the synonym list
#
# statistics(\%syn, \%dict, $max_heads, $min_similarity, 1);

#
# write histogram data
#
if ($file_hist ne "none") {

	export_hist($file_hist);
}



#
# subroutines
#


# this sub reads the whitaker's words dictionary
# hopefuly this will be superceded by a sub that
# can read the Lewis and Short dictionary.

sub read_dictionary {

	my $file = shift;
		
	open (FH, "<", $file) or die "can't read $file: $!";
	
	print STDERR "reading $file\n";
	
	my $pr = new ProgressBar(-s $file);
	
	while (my $line = <FH>) {
	
		$pr->advance(length($line));
	
		$line =~ /#([a-z]+).+? :: (.*?)[^a-z;]*$/i;
		
		if (defined $1 and $2 ) {
					
			my ($head, $def) = ($1, $2);
			
			# add headword to the graph
			$graph->add_vertex($head);
		
			# save the full definition; for homonyms combine them
			if (exists $full_def{$head}) { $full_def{$head} .= "; " }
			
			$full_def{$head} .= $def;
		
			# lowercase the english, divide into words
			$def = lc($def);
			
			my @words = split(/[^a-z]+/, $def);
			
			# add each english word to the dictionary for this headword
			for (@words) {
			
				if ($_ ne "") {
					
					$dict{$head}{$_}++;
				}
			}
		}
	}
	
	close FH;
}

#
# index each head by english words
#

sub make_index {

	print STDERR "indexing\n";
	
	my $pr = new ProgressBar(scalar(keys %dict));
	
	for my $head (keys %dict) {
		
		$pr->advance();
		
		for my $key ( keys %{$dict{$head}} ) {
			
			$index{$key}{$head} = $dict{$head}{$key};
		}
	}
}

# remove from the dictionary defs any english
# words that appear in too many different defs

sub remove_stop_words {

	my ($max_heads) = @_;
	
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
}

#
# calculate term intersections
#

sub intersections {
	
	print STDERR "calculating intersections\n";

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
}

#
# normalize by number of words in each def
#

sub normalize {
	
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
}

#
# organize synonyms for each head
#

sub synonyms {

	my ($min_score) = shift;

	print STDERR "filtering by similarity; min score=$min_score\n";

	my $pr = ProgressBar->new(scalar(keys %score));

	for my $bigram (keys %score) {
		
		$pr->advance();
		
		next if $score{$bigram} < $min_score;
		
		my ($head1, $head2) = split(/~/, $bigram);
		
		next if $head1 eq $head2;
				
		# add an edge to the graph
		
		$graph->add_edge($head1, $head2);
		
		# add to the syn dictionary
		
		push @{$syn{$head1}}, $head2;
		push @{$syn{$head2}}, $head1;
	}
	
	# assign synonym group ids
	
	print STDERR "calculating syn_groups\n";

	@syn_group = $graph->connected_components();
}

#
# print list of synonyms
#

sub export_list {
	
	my $file = shift;
		
	if ($file ne "") {
	
		open (FH, ">", $file) || die "can't write to $file: $!";
		select FH;
	}

	print STDERR "exporting synonym list\n";
	
	my $pr = ProgressBar->new(scalar(keys %syn));
	
	for my $head (sort keys %syn) {
		
		$pr->advance();
		
		print "head: $head\n";
		
		print "full_def: $full_def{$head}\n";
	
		for my $syn (sort {score($head, $b) <=> score($head, $a)} sort @{$syn{$head}}) {
			
			my $spacer = "   ";
			
			if ($full_def{$syn} eq $full_def{$head} && score($head, $syn) < 1) { $spacer =" * " }
			
			print sprintf("$spacer%0.2f  % 18s\t%s\n", score($head, $syn), "'$syn'", $full_def{$syn});
		}
		
		print "\n";
	}
	
	if ($file ne "") { close FH }
}

# print list of synonyms

sub export_list_html {
	
	my $file = shift;
	
	if ($file ne "") {
	
		open (FH, ">", $file) || die "can't write html to $file: $!";
		select FH;
	}

	print STDERR "exporting synonym list as html\n";
	
	my $pr = ProgressBar->new(scalar(keys %syn));
	
	my $all_words  = scalar(keys %dict);
	my $have_syns  = scalar(keys %syn);
	my $syn_groups = scalar(@syn_group); 
	my $no_syns    = $all_words - $have_syns;
	
	my @syns;
	my $total = 0;
	
	for (keys %syn) {
		push @syns, scalar(@{$syn{$_}});
		$total += $syns[-1];
	}
	
	@syns = sort @syns;
	
	my $mean_syns   = sprintf("%.1f", $total/$have_syns);
	my $median_syns = $syns[int(scalar(@syns)/2)];
	
	print "<html>\n";
	print "<head>\n";
	print "  <title>Synonym Test</title>\n";
	print "  <style type=\"text/css\">\n";
	print "    tr.header { margin-top:1em; background-color:#CCCCCC }\n";
	print "  </style>\n";
	print "</head>\n";
	print "<body>\n";
	print "  <h2>Synonym Test</h2>\n";
	print "  <table>\n";
	print "    <tr><td>dictionary</td><td>$file_dict</td></tr>\n";
	print "    <tr><td>max heads</td><td>$max_heads</td></tr>\n";
	print "    <tr><td>min similarity</td><td>$min_similarity</td></tr>\n";
	print "    <tr><td>total words</td><td>$all_words</td></tr>\n";
	print "    <tr><td>words w/o syns</td><td>$no_syns</td></tr>\n";
	print "    <tr><td>synonym groups</td><td>$syn_groups</td></tr>\n";
	print "    <tr><td>for words having synonyms:<td><td></td></tr>\n";
	print "    <tr><td>mean syns</td><td>$mean_syns</td></tr>\n";
	print "    <tr><td>median syns</td><td>$median_syns</td></tr>\n";
	print "  </table>\n";
	print "\n";
	print "  <div class=\"main\">\n";
	print "  <table>\n";
	
	for my $head (sort keys %syn) {
		
		$pr->advance();
		
		print "    <tr class=\"header\"><th>$head</th><td></td><td></td><td>$full_def{$head}</td></tr>\n";
	
		for my $syn (sort {score($head, $b) <=> score($head, $a)} sort @{$syn{$head}}) {
			
			my $spacer = "   ";
			
			if ($full_def{$syn} eq $full_def{$head} && score($head, $syn) < 1) { $spacer =" * " }
			
			print "    <tr>";
			print "<td>$spacer</td>";
			print "<td>" . sprintf("%.2f", score($head, $syn)) . "</td>";
			print "<td>$syn</td>";
			print "<td>$full_def{$syn}</td>";
			print "</tr>\n";
		}
		
		print "\n";
	}
	
	print "  </table>\n";
	print "  </div>\n";
	print "</body>\n";
	print "</html>\n";
	
	if ($file ne "") { close FH };
}

# export the synonym dictionary for tesserae

sub export_cache {
	
	my $file = shift;
	
	print STDERR "writing $file\n";
	
	nstore \%syn, $file;
}

# run the benchmark set

sub export_benchmark {

	my @benchmark = @_;
		
	my %results;
	
	my $pr = ProgressBar->new(scalar(keys %score));
	
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
	
	print STDERR "calculating statistics\n";
	
	my $all_syns = 0;
	my $max_syns = 0;
	my $max_head = "";
	
	my $pr = ProgressBar->new(scalar(keys %syn));
	
	for my $head (sort keys %syn) {
		
		$pr->advance();
			
		my $syns = scalar(@{$syn{$head}});
				
		$all_syns += $syns;
		
		if ($syns > $max_syns) {
			
			$max_syns = $syns;
			$max_head = $head;
		}
	}
	
	print STDERR "file: $file_dict\n";
	print STDERR "total number of headwords: " . scalar(keys %dict) . "\n";
	print STDERR "max headwords per key: $max_heads\n";
	print STDERR "minimum similarity score: $min_similarity\n";
	print STDERR "words that have synonyms: " . scalar(keys %syn) . "\n";
	print STDERR "average number of syns: " . sprintf("%.1f", $all_syns/scalar(keys %syn)) . "\n"; 
	print STDERR "max synonyms: $max_syns ($max_head)\n";
}

#
# export all the dictionary words with syn_group ids
#

sub export_syn_groups {
	
	my $file = shift;

	print STDERR "exporting syn_group data\n";
	
	if ($file ne "") {
		
		open (FH, ">", $file) || die "can't write to $file: $!";
		select FH;
	}
	
	my $pr = ProgressBar->new(scalar(@syn_group));
	
	for my $i (0..$#syn_group) {
	
		$pr->advance();
	
		for (@{$syn_group[$i]}) {
		
			print "$i\t$_\n";
		}
	}

	if ($file ne "") { close FH }
}

#
# export data to draw a histogram of
# synonym "density"
#

sub export_hist {

	my $file = shift;

	print STDERR "exporting histogram data\n";
	
	if ($file ne "") {
		
		open (FH, ">", $file) || die "can't write to $file: $!";
		select FH;
	}

	my %hist;
	
	for (keys %dict) {
	
		my $syns = defined $syn{$_} ? scalar(@{$syn{$_}}) : 0;
		
		# increment the number of syns to include the word itself
		# - makes display on a log-log scale easier
		
		$syns ++;
		
		$hist{$syns}++;
	}
	
	print "words\tsyns\n";
	
	for (sort {$hist{$b} <=> $hist{$a}} keys %hist) {
	
		print "$hist{$_}\t$_\n";
	}
	
	if ($file ne "") { close FH }
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
