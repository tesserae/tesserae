# an attempt to implement the method of Jeff Rydberg-Cox
#
# Chris Forstall
# simplified from rydberg-cox.pl 2012-06-18

use strict;
use warnings;

use Getopt::Long;
use Storable qw(nstore retrieve);

use lib '/Users/chris/Sites/tess.orig/perl';	# PERL_PATH
use TessSystemVars;
use EasyProgressBar;

# define the max number of headwords for a key
# to be included

my $max_heads = 50;

# the minimum similarity score for a synonym

my $min_similarity = .7;

# draw progress bars?

my $quiet = 0;

# the dictionary to parse

my $file_dict_import  = "$fs_data/common/DICTPAGE.RAW";

# the cache file to write

my $file_syn = "$fs_data/common/la.syn.cache";
my $file_semantic = "$fs_data/common/whit.cache";

# set parameters from cmd line options if given 

GetOptions ('max_heads=i' => \$max_heads, 
				'min_similarity=f' => \$min_similarity, 
				'syn=s' => \$file_syn,
				'whitaker=s' => \$file_semantic,
				'quiet' => $quiet);
				
#
# global variables
# 

my %dict;
my %full_def;
my %index;
my %score;
my %syn;

#
# read the dictionary
#

read_dictionary($file_dict_import);

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
# organize synonyms for each head
#

synonyms($min_similarity);

#
# save the cache
#

export_cache();

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
						
		# add to the syn dictionary
		
		push @{$syn{$head1}}, $head2;
		push @{$syn{$head2}}, $head1;
	}
}

# export the synonym dictionary for tesserae

sub export_cache {
	
	print STDERR "writing $file_syn\n";
	nstore \%syn, $file_syn;
	
	print STDERR "writing $file_syn.param\n";	
	nstore [$max_heads, $min_similarity], "$file_syn.param";

	print STDERR "writing $file_semantic\n";
	nstore \%dict, $file_semantic;
}

sub score {

	my ($a, $b) = @_;

	my $score = $score{join("~", sort($a, $b))};

	return defined $score ? $score : 0;
}
