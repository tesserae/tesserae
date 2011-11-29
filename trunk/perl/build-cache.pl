#!/usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# build-cache.pl
#
# this is the archimedes part of prepare.pl
# the idea is that we can parse texts and look up all their
# stems to create common cache files for all the search
# algorithms to use

use strict;
use warnings;

use Storable qw(retrieve nstore);

use TessSystemVars qw(:DEFAULT tcase lcase);

# load the list of canonical reference abbreviations

my %abbr;
my $file_abbr = "$fs_data/common/abbr";

if (-s $file_abbr )	{ %abbr = %{retrieve($file_abbr)} }

# load the list of language designations

my %lang;
my $file_lang = "$fs_data/common/lang";

if (-s $file_lang )	{ %lang = %{retrieve($file_lang)} }

# regular expression describing chars that aren't part of any word

my %non_word = (
	'la' => qr([^a-zA-Z]+), 
	'grc' => qr([^a-z\*\(\)\\\/\=\|\+']+) );

# normal operation requires looking up headwords on the archimedes morphology server
# to suppress this set the following to true

my $no_archimedes = 0;

if ( grep {/--no-archimedes/} @ARGV) { $no_archimedes = 1}

# normal behaviour is to write new stems acquired from archimedes to the main cache
#  -- if lookup isn't working correctly, this might cause a good cache to be over-
#     written by a broken one.
#  -- set the following to true to prevent writing to the cache file

my $no_write_cache = 0;

# some parameters to pass along to the archimedes server

my $archimedes_debug = 0;

# to look up headwords you need this module, not standard on my Mac's perl install

unless ($no_archimedes)
{
	use Frontier::Client;
}

my $usage = "usage: prepare.pl [--la|grc] TEXT [TEXT2 TEXT3 ...]\n";

my $lang;
my $lang_override;
my $lang_prev = "";

# a word count

my %count;

# the dictionary of stems

my %stem;

# parse command line arguments

while (my $file_in = shift @ARGV)
{
	if ($file_in =~ /^--/)
	{
		if ($file_in =~ /^--(la|grc)/)
		{
			$lang_override = $1;
		}
		next;
	}

	#
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if ($file_in !~ /\.tess/)
	{
		if (-d $file_in)
		{
			opendir (DH, $file_in);

			push @ARGV, (grep {/\.part\./ && -f} map { "$file_in/$_" } readdir DH);

			closedir (DH);
		}

		next;
	}

	# path to parsed output

	my $name = $file_in;

	$name =~ s/.*\///;
	$name =~ s/\.tess//;

	# determine language from user input, cached from last
	# time, guess from path to file, or just give up

	if ( defined $lang_override )
	{
		$lang = $lang_override;
	}
	elsif ( defined $lang{$name} )
	{
		$lang = $lang{$name};
	}
	elsif ( $file_in =~ /\/(la|grc)\// )
	{
		$lang = $1;
	}
	else
	{
		die "please specify language using --la|grc";
	}

	# path to dictionaries

	my $file_stems = "$fs_data/common/$lang.stem.cache";
	my $file_semantics = "$fs_data/common/$lang.semantic.cache";

	#
	# parse the text into words
	#

	print STDERR "reading text: $file_in\n";

	# initialize the word count for each text

	%count = ();

	# this will count line refs

	my %ref;

	# open the input text

	open (TEXT, $file_in) or die("Can't open file ".$file_in);

	# examine each line of the input text

	while (<TEXT>) 
	{
		# remove newline	

		chomp;

		# parse a line of text; reads in verse number and the verse. 
		# Assumption is that a line looks like:
		# <001> this is a verse

		/^<(.+)>\s*(.*)/;

		my $verseno = $1;
		my $verse = $2;

		next unless (defined $verseno and defined $verse);

		# from the canonical citation for the line,
		# get the abbreviation of the work
		#  - I'm counting all refs using  a hash and taking
		#    the most frequent one to be correct.

		$verseno =~ s/^(.*)\s//;

		$ref{$1}++;

		# split string into words on non-word chars
		#
		# --what consititutes a non-word char depends on the
		# language.  this needs to be made more elegant if we're
		# going to use the same process.pl for latin & greek

		$verse =~ s/$non_word{$lang}/ /g;
	
		my @words = split /\s+/, $verse;

		for my $form (@words)
		{
			next if ($form eq "");

			$count{lcase($lang, $form)}++;
		}
	}

	close TEXT;

	print STDERR scalar(keys %count) . " unique forms\n";

	#
	# load stem cache
	#

	print STDERR "checking stem cache $file_stems\n";

	if ($lang ne $lang_prev)
	{

		%stem = ();

		if (-s $file_stems) 
		{
			%stem = %{retrieve($file_stems)};
		}
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

	# add this ref to the list of abbreviations
	# if it isn't already there

	unless (defined $abbr{$name})
	{
		$abbr{$name} = (sort { $ref{$b} <=> $ref{$a} } keys %ref)[0];
		nstore \%abbr, $file_abbr;
	}

	# save the language designation for this file

	unless (defined $lang{$name})
	{	
		$lang{$name} = $lang;
		nstore \%lang, $file_lang;
	}

}
exit;


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

	my $res = $client->call('lemma', "-" . uc($lang), [@batch, tcase($lang, @batch)]);
	
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


