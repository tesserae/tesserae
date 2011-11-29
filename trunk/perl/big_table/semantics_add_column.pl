#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# semantics_add_column.pl
#
# copy a column from the words table to the semantics table
#

use strict;
use warnings;

use TessSystemVars;
use Storable qw(nstore retrieve);

my $lang_default = 'la';
my $lang_prev = "";
my $lang;

my %stem_lookup;
my %semantic_lookup;

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

		my $file_stem_cache = "$fs_data/common/$lang.stem.cache";

		unless (-r $file_stem_cache) { die "can't find $file_stem_cache" }

		%stem_lookup = %{ retrieve($file_stem_cache) };
	
		# load the cache of semantic tags

		my $file_semantic_cache = "$fs_data/common/$lang.semantic.cache";

		unless (-r $file_semantic_cache) { die "can't find $file_semantic_cache" }

		%semantic_lookup = %{ retrieve($file_semantic_cache) };
	}

	# get rid of any path or file extension

	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	my $file_in = "$fs_data/big_table/$lang/word/$name";

	# make sure the column in the word table is complete

	for ( qw/line phrase index_line_ext index_line_int index_phrase_ext index_phrase_int/ )
	{
		unless (-r "$file_in.$_") { die "$file_in.$_ does not exist or is unreadable" }
	}

	# retrieve the column from the word table

	print STDERR "reading table data\n";

	my %word_index_line_int = %{ retrieve("$file_in.index_line_int") };
	my %word_index_line_ext = %{ retrieve("$file_in.index_line_ext") };

	my %word_index_phrase_int = %{ retrieve("$file_in.index_phrase_int") };
	my %word_index_phrase_ext = %{ retrieve("$file_in.index_phrase_ext") };

	#
	# create the new column
	#

	print STDERR "processing semantic tags\n";

	#
	# first the line-based table
	#

	# initialize an empty stem column

	my %semantic_index_line_int;
	my %semantic_index_line_ext;

	# for each word in the text

	for my $word (keys %word_index_line_ext)
	{
		# this array holds multi-word english definitions

		my @eng_def;

		# add the definitions of the stems, if any 

		if ( defined $stem_lookup{$word} )
		{

			for my $stem (@{$stem_lookup{$word}})
			{

				if (defined $semantic_lookup{$stem})				
				{
					push @def, @{$semantic_lookup{$stem}};
				}
			}
		}
	
		# add the definitions of the word itself, if any

		if (defined $semantic_lookup{$word})
		{
			push @def, @{$semantic_lookup{$word}};
		}

		#
		# now break the definitions into separate words
		# - don't include duplicates

		my %tag;

		for my $full_def (@def)
		{
			$full_def = lc($full_def);

			for ( split /[^a-z]+/, $full_def )
			{
				next if ($_ eq "");

				$tag{$_} = 1;
			}
		}

		#
		# add an entry to the semantic table for each tag
		#

		for my $tag(keys %tag)
		{ 
			for my $i (0..$#{$word_index_line_ext{$word}})
			{
				push @{$semantic_index_line_int{$stem}}, ${$word_index_line_int{$word}}[$i];
				push @{$semantic_index_line_ext{$stem}}, ${$word_index_line_ext{$word}}[$i];
			}
		}
	}
	
	#
	# do the same thing for the phrase table as for lines
	#

	my %semantic_index_phrase_int;
	my %semantic_index_phrase_ext;

	# for each word in the text

	for my $word (keys %word_index_phrase_ext)
	{
		# this array holds multi-word english definitions

		my @eng_def;

		# add the definitions of the stems, if any 

		if ( defined $stem_lookup{$word} )
		{

			for my $stem (@{$stem_lookup{$word}})
			{

				if (defined $semantic_lookup{$stem})				
				{
					push @def, @{$semantic_lookup{$stem}};
				}
			}
		}
	
		# add the definitions of the word itself, if any

		if (defined $semantic_lookup{$word})
		{
			push @def, @{$semantic_lookup{$word}};
		}

		#
		# now break the definitions into separate words
		# - don't include duplicates

		my %tag;

		for my $full_def (@def)
		{
			$full_def = lc($full_def);

			for ( split /[^a-z]+/, $full_def )
			{
				next if ($_ eq "");

				$tag{$_} = 1;
			}
		}

		#
		# add an entry to the semantic table for each tag
		#

		for my $tag(keys %tag)
		{ 
			for my $i (0..$#{$word_index_phrase_ext{$word}})
			{
				push @{$semantic_index_phrase_int{$stem}}, ${$word_index_phrase_int{$word}}[$i];
				push @{$semantic_index_phrase_ext{$stem}}, ${$word_index_phrase_ext{$word}}[$i];
			}
		}
	}
	
	#
	# write the new column
	#
	
	my $file_out = "$fs_data/big_table/$lang/semantic/$name";

	print STDERR "writing $file_out.index_line_int\n";
	nstore \%stem_index_line_int, "$file_out.index_line_int";

	print STDERR "writing $file_out.index_line_ext\n";
	nstore \%stem_index_line_ext, "$file_out.index_line_ext";

	print STDERR "writing $file_out.index_phrase_int\n";
	nstore \%stem_index_phrase_int, "$file_out.index_phrase_int";

	print STDERR "writing $file_out.index_phrase_ext\n";
	nstore \%stem_index_phrase_ext, "$file_out.index_phrase_ext";
}
