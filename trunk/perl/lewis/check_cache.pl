#
# check_cache.pl
#
# a little script to read every key and every value
# in one of the dictionaries.  can be modified to 
# check for whatever interests you; right now i want
# to look for empty strings and capital letters

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

use TessSystemVars;

use Storable;

# prepare for unicode output

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# language to use; set for each file

my $lang;
my $lang_override;

# these will count some things I don't want in my caches

my %empty;
my %undefined;
my %caps;
my %other;

# get the cache to check from the cmd line

while ( my $file_cache = shift @ARGV)
{
	
	# allow user to specify language on cmd line
	
	if ( $file_cache =~ /^--(la|grc)/)
	{
		$lang_override = $1;
		next;
	}

	# make sure the cache exists

	unless ( -s $file_cache )
	{
		# the user may have just written the file name
		# and assumed the usual dictionary path

		my $file_cache_orig = $file_cache;

		$file_cache =~ s/^.*\///;
		$file_cache =~ s/\.cache$//;
		$file_cache = "$fs_data/common/$file_cache.cache";

		unless (-s $file_cache )
		{
			die "can't read cache $file_cache_orig or $file_cache";
		}
	}

	# set language
	
	if ( defined $lang_override )
	{
		$lang = $lang_override;
	}
	else
	{
		$file_cache =~ /[^\.](la|grc)\./;

		$lang = $1 || die "can't figure out the language of $file_cache";
	}
	
	# a set of delimiters for displaying results,
	# in order of preference

	my @delimit = (', ', ' : ', ' # ', ' $ ', "\n");

	# load cache 

	print STDERR "reading $file_cache\n";

	my %cache = %{ retrieve($file_cache) };

	#
	# check the cache
	#

	my @key = sort keys %cache;
	my @value;

	# reset the counters

	%empty    	= ( 'key' => 0,	'value' => 0  );
	%undefined	= ( 'key' => 0,	'value' => 0  );
	%caps     	= ( 'key' => [],	'value' => [] );
	%other     	= ( 'key' => [],	'value' => [] );

	# read every entry

	for (@key)
	{

		test('key', $_);

		for (@{$cache{$_}})
		{

			test('value', $_);

			# replace newlines with '\n'

			s/\n/\\n/g;

			# if the chosen delimiter occurs in the values, 
			# use another one

			if ( /$delimit[0]/ )	{ shift @delimit }

			# add this to the array of values

			push @value, $_;
		}
	}

	# print statistics to STDERR

	print STDERR scalar(@key) . " keys; " . scalar(@value) . " values.\n";

	for my $cat (qw/key value/)
	{
		print STDERR "$empty{$cat} empty ${cat}s\n";
		print STDERR "$undefined{$cat} undefined ${cat}s\n";
		print STDERR scalar(@{$caps{$cat}}) . " capitalized ${cat}s\n";
		print STDERR scalar(@{$other{$cat}}) . " other irregular ${cat}s\n\n";
	}

	# print the whole cache to STDOUT

	print "cache: $file_cache\n";

	for (@key)
	{
		print "$_: ";

		print join($delimit[0], @{$cache{$_}});

		print  "\n";
	}
}

sub test
{
	my $cat = shift;
	my $test = shift;

	# test for empty strings and undefined variables

	if ( $test eq "" )   	{ $empty{$cat}++ }
	if ( !defined $test )	{ $undefined{$cat}++ }

	# language specific checks

	if ($lang eq 'la')
	{
		if ( $test =~ /[A-Z]/ )	{ push @{$caps{$cat}},  $test }
		if ( $test =~ /[Jj]/  )	{ push @{$other{$cat}}, $test }
	}

	elsif ($lang eq 'grc')
	{
		if ( $test =~ /^\*/  )  { push @{$caps{$cat}},  $test }
	}
}
