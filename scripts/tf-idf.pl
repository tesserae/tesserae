# create a database of inverse-document frequencies for all words in Tesserae
#
# created for large-scale score tests
# 
# Chris Forstall
# 2012-06-08

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

# load additional modules necessary for this script

use Storable qw(nstore retrieve);

#
# get the list of texts from Tesserae
#

my $lang = 'la';

my $dir = catdir($fs{data}, 'v3', $lang, 'word');

opendir (DH, $dir) || die "can't read directory $dir: $!";

my @file = grep { /\.index_phrase_ext/ } readdir(DH);

closedir DH;

# don't use full texts which also exist as parts

for (my $i = $#file; $i >= 0; $i--) {

	if ($file[$i] !~ /\.part\./) {
	
		$file[$i] =~ /(.*)\.index_phrase_ext/;
		
		if (grep {/$1\.part\./} @file) { splice @file, $i, 1 }
	}
}


#
# do a word count for every phrase and every text
#

# this counts the number of phrases containing each word

my %phrase_count;

# this counts the total number of phrases in the whole corpus

my $total_phrases;

# this counts the number of documents containing each word

my %document_count;

# check each text's index:

print STDERR "reading text indices\n";

my $pr = ProgressBar->new(scalar(@file));

for my $name (@file) {
		
		$pr->advance();
		
		my $file = catfile($fs{data}, 'v3', $lang, 'word', $name);
		
		my %index = %{ retrieve($file) };
		
		for my $word (keys %index) {

			# count the word once for this text
		
			$document_count{$word}++;
		
			# then count once for each phrase in which the text occurs:
			# first squash duplicates
		
			my %uniq;
			
			for (@{$index{$word}}) { $uniq{$_} = 1 }
		
			$phrase_count{$word} += scalar(keys %uniq);
		}
		
		# load the list of all phrases, 
		# add the number of phrases
		# to the running total.
		
		$file =~ s/\.index_phrase_ext/\.phrase/;
		
		my @phrase = @{ retrieve($file) };
		
		$total_phrases += scalar(@phrase);
}

#
# convert the counts to inverse-document frequency
#

print STDERR "calculating document-specific frequencies\n";

$pr = ProgressBar->new(scalar keys %document_count);

for (keys %document_count) {

	$pr->advance();
	
	$document_count{$_} = log(scalar(@file)/$document_count{$_});
}

print STDERR "calculating phrase-specific frequencies\n";

$pr = ProgressBar->new(scalar keys %document_count);

for (keys %phrase_count) {
	
	$pr->advance();

	$phrase_count{$_} = log($total_phrases/$phrase_count{$_});
}

#
# save
#

nstore \%document_count, catfile($fs{data}, "$lang.idf_text");
nstore \%phrase_count, catfile($fs{data}, "$lang.idf_phrase");
