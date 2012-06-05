#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

#
# stems_add_column2.pl
#
# copy a column from the word table to the stems table
#

use strict;
use warnings;

use TessSystemVars;

use File::Path qw(mkpath rmtree);
use Storable qw(nstore retrieve);

my $lang_default = 'la';
my $lang_prev = "";
my $lang;

my %stem_lookup;

#
# process the files specified as cmd line args
#

while (my $name = shift @ARGV)
{

	# lang may be set on cmd line

	if ( $name =~ /^--(la|grc)/)
	{
		$lang_default = $1;
		next;
	}

	# normally, look for lang in path

	if ( $name =~ /\/(la|grc)\// )
	{
		$lang = $1;
	}
	else
	{
		$lang = $lang_default;
	}

    #
    # large files split into parts are kept in their
    # own subdirectories; if an arg has no .tess extension
    # it may be such a directory

    if ($name !~ /\.tess/)
    {
        if (-d $name)
        {
            opendir (DH, $name);

            push @ARGV, (grep {/\.part\./ && -f} map { "$name/$_" } readdir DH);

            closedir (DH);
        }

        next;
    }

	# if lang has changed, load the correct cache

	if ($lang ne $lang_prev)
	{
		# load the cache of stems

		my $file_stem_cache = "$fs_data/common/dik.$lang.stem.cache";

		unless (-r $file_stem_cache) { die "can't find $file_stem_cache" }

		%stem_lookup = %{ retrieve($file_stem_cache) };
	}

	# get rid of any path or file extension

	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	my $file_base = "$fs_data/test/$lang/$name/$name";

	# make sure the column in the word table is complete

	for ( qw/word display line phrase count index_word index_line index_phrase phrase_lines/ )
	{
		unless (-r "$file_base.$_") { die "$file_base.$_ does not exist or is unreadable" }
	}

	# retrieve the column from the word table

	print STDERR "reading table data\n";

	my %index_word = %{ retrieve("$file_base.index_word") };

	#
	# create the new column
	#

	print STDERR "processing stems\n";

	#
	# first the line-based table
	#

	# initialize an empty stem column

	my %index_stem;

	# for each word in the text

	for my $word (keys %index_word)
	{
		# only proceed if it has stems in the cache

		if ( defined $stem_lookup{$word} )
		{
			# for each stem

			for my $stem (@{$stem_lookup{$word}})
			{
				# skip blank stems introduced by error

				next if $stem eq "";

				# add an entry to the stem-specific index for each entry in the word index

				push @{$index_stem{$stem}}, @{$index_word{$word}};
			}
		}
	}
	
	# write the new column

	print STDERR "writing $file_base.index_stem\n";
	nstore \%index_stem, "$file_base.index_stem";
}
