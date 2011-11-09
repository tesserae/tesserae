#!/usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/var/www/tesserae/perl';	# PERL_PATH

#
# gk_prepare.pl
#
# a modification of the new prepare.pl to accommodate betacode greek texts
#

use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use Storable qw(retrieve nstore);
use Files;

my $lang = "la";

my %non_word = ('la' => qr([^a-zA-Z]+), 'grc' => qr([^a-z\*\(\)\\\/\=\|\+']+));

# normal operation requires looking up headwords on the archimedes morphology server
# to suppress this set the following to true

my $no_archimedes = 0;

# forms not found on archimedes will be attempted a second time using alternate
# orthography.  to suppress this stage, set the following to true

my $no_alts = 1;

# normal behaviour is to write new stems acquired from archimedes to the main cache
#  -- if lookup isn't working correctly, this might cause a good cache to be over-
#     written by a broken one.
#  -- set the following to true to prevent writing to the cache file

my $no_write_cache = 0;

# some parameters to pass along to the archimedes server

my $archimedes_debug = 0;
my $archimedes_lang = uc($lang);

# to look up headwords you need this module, not standard on my Mac's perl install

unless ($no_archimedes)
{
	use Frontier::Client;
}

# some more variables

my $usage = "usage: prepare.pl TEXT\n";

my $file_in = shift @ARGV || die $usage;

my $file_out = $file_in;

$file_out =~ s/.+\//$fs_data\/v2\/parsed\//;
$file_out =~ s/(\.tess)?$/\.parsed/;

my $file_stems = "$fs_data/common/$lang.stem.cache";
my $file_semantics = "$fs_data/common/$lang.semantic.cache";

print STDERR "input text: $file_in\nparsed corpus output file: $file_out\n\n";

#
# parse the text into words and phrases
#

print STDERR "reading text: $file_in\n";

# this will hold all the Phrases

my @phrase_array;

# this will count word forms

my %count;

# open the input text

open (TEXT, $file_in) or die("Can't open file ".$file_in);

# this will hold partial phrases across lines

my $held_text = "";

# this will hold the working phrase

my $phrase;

# examine each line of the input text

while (<TEXT>) 
{
	# remove newline	

	chomp;

	# parse a line of text; reads in verse number and the verse. Assumption is that a line looks like:
	# <001> this is a verse

	/^<(.+)>\s*(.*)/;

	my $verseno = $1;
	my $verse = $2;

	next unless (defined $verseno and defined $verse);

	# if a line begins with spaces or phrase-punct chars, delete them

	$verse =~ s/^[\.\?\!;:\s]+//;

	# if $held_text is null, then the last line ended with a phrase end
	# 
	# create a new phrase for this line

	if ($held_text eq "")
	{
		$phrase = Phrase->new();
	}

	# if the current line has a phrase-punct char in it, then add everything
	# before it to the current phrase, create a new phrase for what remains,
	# and repeat in case there are still more phrase-puncts in the same line
	
	while ($verse =~ s/([^\.\?\!;:]+[\.\?\!;:](?:$non_word{$lang})*)//)
	{

		# finish the current phrase

		# first, add the complete phrase as a string
			
		$phrase->phrase($held_text.$1);

		# then parse the words from this line before the punct.

		add_line(\$phrase, $verseno, $1);	

		# add the finished object to the cumulative array

		push @phrase_array, $phrase;

		# clear the hold-over buffer

		$held_text = "";

		# if the next phrase begins on this line, create it

		if ($verse =~ /[A-Za-z]/)
		{
			$phrase = Phrase->new();
		}
	}

	# if there's some text left in this line

	if ($verse =~ /[A-Za-z]/)
	{
		# save whatever is left to carry over to the next line

		$held_text .= $verse;
	
		# and add the remaining words to the current phrase
	
		add_line(\$phrase, $verseno, $verse);
	}
}

close TEXT;

print STDERR scalar(@phrase_array) . " phrases\n";

print STDERR scalar(keys %count) . " unique forms\n";

#
# load stem cache
#

print STDERR "checking stem cache $file_stems\n";

my %stem = ();

if (-s $file_stems) 
{
	%stem = %{retrieve($file_stems)};
}

print STDERR "cache contains " . scalar(keys %stem) . " forms\n\n";


# these arrays hold keys to be looked up, and those that return no results

my @working = sort keys %count;
my @failed = ();

# now check the cache for each form in the text

for (@working)
{
	# if it's not in the cache, add it to the list to look up.

	unless (defined $stem{$_} and ${$stem{$_}}[0] ne "")
	{
		push @failed, $_;
	}
}


#
# look up forms that weren't in the cache
#

unless ($no_archimedes)
{

	@working = splice @failed;

	print STDERR scalar(@working) . " forms to look up on archimedes.\n";

	# this loop queries the archimedes server for forms in batches
	#
	# doing them in batches makes things go faster and requires fewer
	# calls to their server.
	
	my $total = scalar(@working);
	my $progress = 0;

	print STDERR "0% |" . (" "x20) . "| 100%" . "\r0% |";

	while (my @batch = splice(@working, 0, 50))
	{

		if (($total-scalar(@working))/$total > $progress + .05)
		{
			print STDERR ".";
			$progress += .05;
		}
	
		push @failed, archimedes(@batch);
		
		# write the cache with each batch, so that if the program fails
		# somewhere in a big list, we at least save the earlier results

		unless ($no_write_cache)
		{
			nstore \%stem, $file_stems;
		}
	}

	print STDERR "\n\n";

}

print STDERR scalar(@failed) . " forms couldn't be stemmed: \n";

print STDERR join(" ", sort @failed) . "\n\n";

#
# load semantic tags
#

print STDERR "checking semantic cache $file_semantics\n";

my %semantic = ();

if (-s $file_semantics) 
{
	%semantic = %{retrieve($file_semantics)};
}

print STDERR "cache contains " . scalar(keys %semantic) . " forms\n\n";

#
# go back and reprocess
#
#   - convert forms to lowercase
#   - add stems
#   - add semantic tags
#   - add phrase ids

print STDERR "adding stems, semantic tags to Phrases...\n";

for my $phraseno (0..$#phrase_array)
{
	my $phrase = $phrase_array[$phraseno];

	bless $phrase, 'Phrase';

	for my $word (@{$phrase->wordarray()})
	{

		bless $word, 'Word';

		my $form = $word->word();

		# convert the form to lowercase for exact form matching

		$word->word($form);

		# add stems

		for ( @{$stem{$form}} )
		{
			next if ($_ eq "");

			$word->add_stem($_);
		}

		# add semantic tags

		for ( @{$semantic{lc($form)}} )
		{
			$word->add_semantic_tag($_);
		}

		# note what phrase id it belongs to

		$word->phraseno($phraseno);

	}
}

print STDERR "writing $file_out\n";
nstore \@phrase_array, $file_out;

exit;

sub add_line
{
	my $phrase_ref	= shift || die "add_line called without phrase ref";
	my $verseno		= shift || die "add_line called without verseno";
	my $string		= shift || die "add_line called without string";

	my $phrase = $$phrase_ref;

	bless $phrase, 'Phrase';

	# split string into words on non-word chars
	#
	# --what consititutes a non-word char depends on the
	# language.  this needs to be made more elegant if we're
	# going to use the same process.pl for latin & greek

	$string =~ s/$non_word{$lang}/ /g;
	
	my @words = split /\s+/, $string;

	for my $form (@words)
	{
		next if ($form eq "");

		# create a new Word

		my $word = Word->new();

		# for display, the form as it appeared in the text

		$word->display($form);

		# for exact word matching, the lowercase version of same

		$word->word(lcase($lang, $form));

		# its locus

		$word->verseno($verseno);

		# now add it to the current
 
		$phrase->add_word($word);

		# add to the token count

		$count{$word->word}++;
	}

	return;
}

#
# this subroutine looks up a batch of forms on archimedes
#

sub archimedes
{
	
	my @batch = @_;
	my @failed;
	
	# initialize the client

	my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => $archimedes_debug);
	
	# make the call

	my $res = $client->call('lemma', "-" . uc($archimedes_lang), [@batch, tcase($lang, @batch)]);
	
	# add the results to the cache

	for my $w ( keys %{$res} )
	{

		# if there's already a value for a different capitalization
		# then merge them
			
		my %uniq;

		for (@{$stem{lcase($lang, $w)}}, @{$res->{$w}})
		{
				
			$uniq{lcase($lang, $_)} = 1;
		}

		$stem{lcase($lang, $w)} = [keys %uniq];		
		
		# otherwise leave the cache value for that key undefined
	}
	
	#
	# check the forms originally submitted to see how many succeeded
	#
	
	for (@batch)
	{
		unless ( defined $stem{$_} )	{ push @failed, $_ }
	}
	
	return @failed;
}

#
# language-specific lower-case and title-case functions

sub lcase
{
	my $lang = shift;

	my @string = @_;

	for (@string)
	{
	
		if ($lang eq 'la')
		{
			tr/A-Z/a-z/;
			tr/jJ/iI/;
		}
	
		if ($lang eq 'grc')
		{
			s/^\*([\(\)\/\\\|\=\+]*)([a-z])/$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}

sub tcase
{
	my $lang = shift;

	my @string = @_;
	
	for (@string)
	{

		$_ = lcase($lang, $_);

		if ($lang eq 'la')
		{
			s/^([a-z])/uc($1)/e;
		}
	
		if ($lang eq 'grc')
		{
			s/^([a-z])([\(\)\/\\\|\=\+]*)/\*$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}
