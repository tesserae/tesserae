#
# big_table_frequencies.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

use TessSystemVars;

use Storable qw(nstore retrieve);

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV)
{
	if (/gr/)	{ push @lang, "grc" }
	if (/la/)	{ push @lang, "la"	}
}

#
# main loop
#

# word counts come from documents already parsed.
# stem counts are based on word counts, but also 
# use the cached stem dictionary
#

for my $lang(@lang)
{

	my $file_stem_cache = "$fs_data/common/$lang.stem.cache";

	# get a list of all the word counts

	my @count_files;

	opendir (DH, "$fs_data/v3/$lang/word");

	push @count_files, (grep {/\.count$/ && !/\.part\./ && -f} map { "$fs_data/v3/$lang/word/$_" } readdir DH);

	closedir (DH);

	#
	# combine the counts for each file to get a corpus count
	#

	my %count;
	my %total;

	for (@count_files)
	{
	
		print STDERR "reading $_\n";
		
		# get just the short name from the file
		
		/.*\/(.+)\.count/;
		my $text_key = $1;

		# retrieve the count

		$count{$text_key} = retrieve($_);

		for (keys %{$count{$text_key}})
		{
			$total{$_} += $count{$text_key}{$_};
		}
	}

	print STDERR "writing $fs_data/common/$lang.word_count\n";

	nstore \%total, "$fs_data/common/$lang.word_count";

	#
	# stem counts
	#

	print STDERR "reading $file_stem_cache\n";

	my %cache = %{retrieve($file_stem_cache)};

	print STDERR "calculating stem counts\n";

	my %stem_count;

	for my $word (keys %total)
	{
		if ( defined $cache{$word} )
		{
			for my $stem ( @{$cache{$word}} )
			{
				$stem_count{$stem} += $total{$word};
			}
		}
	}

	print STDERR "writing $fs_data/common/$lang.stem_count\n";

	nstore \%stem_count, "$fs_data/common/$lang.stem_count";

	print STDERR "\n";
}
