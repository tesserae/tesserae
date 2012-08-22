#! /opt/local/bin/perl5.12

#
# a new version of prepare.pl
#
# I got rid of the statistical analysis--to be implemented as a separate script
# 
# I also added semantic tagging using lewis.cache
#
# -Chris Forstall, 2011/10/25

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use Storable qw(retrieve nstore);
use Files;

# normal operation requires looking up headwords on the archimedes morphology server
# to suppress this set the following to true

my $no_archimedes = 0;

# to look up headwords you need this module, not standard on my Mac's perl install
unless ($no_archimedes)
{
	use Frontier::Client;
}

# some more variables

my $usage = "usage: prepare.pl TEXT\n";

my $file_in = shift @ARGV || die $usage;

my $file_out = $file_in;

$file_out =~ s/.+\//${fs_data}v2\/parsed\//;
$file_out =~ s/(\.tess)?$/\.parsed/;

my $file_stems = "$fs_data/common/la.stem.cache";
my $file_lewis = "$fs_data/common/la.semantic.cache";

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

	my $verseno = $_;
	my $verse = $_;

	$verseno =~ s/\<(.+)\>(.*)/$1/s;
	$verse =~ s/\<(.+)\>\s*(.*)/$2/s;

	# if a line begins with spaces or phrase-punct chars, delete them

	$verse =~ s/^[\.\?\!;:\s]+//;

	# skip lines with no locus

	next if ($verseno eq "");

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

	while ($verse =~ s/([^\.\?\!;:]+[\.\?\!;:]+)//)
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
# build stem cache
#

print STDERR "checking stem cache $file_stems\n";

my %cache = ();

if (-s $file_stems) 
{
	%cache = %{retrieve($file_stems)};
}

print STDERR "cache contains " . scalar(keys %cache) . " forms\n\n";

# this array will hold forms to look up on archimedes

my @archimedes;

# these arrays hold keys that return no results

my @failed;
my @failed_twice;

# now check the cache for each form in the text

for (sort keys %count)
{
	# if it's not in the cache, add it to the list to look up.

	unless (defined $cache{$_} and ${$cache{$_}}[0] ne "")
	{
		push @archimedes, $_;
	}
}

unless ($no_archimedes)
{

	print STDERR scalar(@archimedes) . " forms to look up on archimedes.\n";

	# this loop queries the archimedes server for 10 forms at a time
	#
	# doing them in batches makes things go faster and requires fewer
	# calls to their server.

	my $total = scalar(@archimedes);
	my $progress = 0;

	print STDERR "0% |" . (" "x20) . "| 100%" . "\r0% |";

	while (my @batch = splice(@archimedes, 0, 10))
	{

		if (($total-scalar(@archimedes))/$total > $progress + .05)
		{
			print STDERR ".";
			$progress += .05;
		}
	
		# initialize the client
	
		my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => 0);
		
		# make the call
	
		my $res = $client->call('lemma', "-LA", [@batch]);
		
		# check the results
		#
		# what we get back should be a hash with one key per form we asked for
		# check each of the forms to make sure it got a result

		for my $w ( @batch )
		{

			# if there's a key, then enter the value into the cache

			if ( defined $res->{$w} )
	        	{
				my $test = $res->{$w};

				$cache{$w} = $test;
	        	}
			# otherwise leave the cache value for that key blank
			else
			{
				$cache{$w} = [""];
				push @failed, $w;
			}
		}

		# write the cache with each batch, so that if the program fails
		# somewhere in a big list, we at least save the earlier results

		nstore \%cache, $file_stems;
	}

	print STDERR "\n\n";

	print STDERR scalar(@failed) . " forms got no results from archimedes. Checking possible alternate orthography.\n";

	$progress = 0;
	$total = scalar(@failed);
	my $old_progress = 0;

	print STDERR "0% |" . (" "x20) . "| 100%" . "\r0% |";

	#
	# look up failed forms a second time using alternate spelling
	#

	for my $form (@failed)
	{

		$progress += 1;

		if ($progress/$total > $old_progress+.05)
		{
			print STDERR ".";
			$old_progress += .05;
		}
	
		my @alt = alt($form);

		for ( @alt )
		{
			if (defined($cache{$_}) and ${$cache{$_}}[0] ne "")
			{

				$cache{$form} = $cache{$_};
				last;
			}
		}

		unless (defined ($cache{$form}) and ${$cache{$form}}[0] ne "")
		{

			# check archimedes for alternate forms

			# initialize the client

			my $client = Frontier::Client->new( url => "http://archimedes.mpiwg-berlin.mpg.de:8098/RPC2", debug => 0);

			# make the call

			my $res = $client->call('lemma', "-LA", [alt($form)]);

			# check the results

			for ( @alt )
			{
                		if (defined($res->{$_}))
                		{
					my $test = $res->{$_};

					$cache{$form} = $test;
					last;
				}
			}

			unless (defined ($cache{$form}) and ${$cache{$form}}[0] ne "")
			{
				push @failed_twice, $form;
			}
		}
	}

	print STDERR "\n\n";

	nstore \%cache, $file_stems;
}
# if no_archimedes is set, just pass on the forms that weren't in the cache
else
{
	@failed_twice = @archimedes;
}

print STDERR scalar(@failed_twice) . " forms couldn't be stemmed: \n";

print STDERR join(" ", sort @failed_twice) . "\n\n";

#
# go back and reprocess
#
#   - convert forms to lowercase
#   - add stems
#   - add semantic tags
#   - add phrase ids

my %lewis = %{ retrieve($file_lewis) };


print STDERR "processing...\n";

for my $phraseno (0..$#phrase_array)
{
	my $phrase = $phrase_array[$phraseno];

	bless $phrase, 'Phrase';

	for my $word (@{$phrase->wordarray()})
	{

		bless $word, 'Word';

		my $form = $word->word();

		# convert the form to lowercase for exact form matching

		$word->word(lc($form));

		# add stems

		for ( @{$cache{$form}} )
		{
			next if ($_ eq "");

			$word->add_stem($_);
		}

		# add semantic tags

		for ( @{$lewis{lc($form)}} )
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
	my $verseno	= shift || die "add_line called without verseno";
	my $string	= shift || die "add_line called without string";

	my $phrase = $$phrase_ref;

	bless $phrase, 'Phrase';

	my @words = split /[^A-Za-z]/, $string;

	for my $form (@words)
        {
		next if ($form eq "");

		# add to the count

		$count{$form}++;

                # create a new Word

                my $word = Word->new();

                # for exact-word matching, the superficial form

                $word->word($form);

                # its locus

                $word->verseno($verseno);

                # now add it to the current phrase

                $phrase->add_word($word);
        }

	return;
}


# this sub creates a list of possible alternate forms for words
# not found in the dictionary.
#
# they're returned in order of likely usefulness

sub alt
{
	my $form = shift;

	# all lowercase

	my $lower = lc($form);

	# titlecase

	my $title = $lower;
	$title =~ s/(.)/uc($1)/e;

	# replace j and v with i and u
	
	my $semivowel = $lower;
	$semivowel =~ tr/jv/iu/;

	return ($lower, $title, $semivowel);
}
