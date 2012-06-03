#! /opt/local/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/tesserae/perl';	# PERL_PATH

#
# synonyms_add_column.pl
#
# copy a column from the words table to the synonyms table
#
# this is an alternative to semantics_add_table
# the idea is that we have a pre-compiled dictionary of
# synonyms for each headword, just as we have a dictionary
# of headwords for each form.

use strict;
use warnings;

use TessSystemVars;
use Storable qw(nstore retrieve);

my $lang_default = 'la';
my $lang_prev = "";
my $lang;

my %stem_lookup;
my %syn_lookup;

my $self_match = 0;

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

		my $file_syn_cache = "$fs_data/common/$lang.syn.cache";

		unless (-r $file_syn_cache) { die "can't find $file_syn_cache" }

		%syn_lookup = %{ retrieve($file_syn_cache) };
	}

	# get rid of any path or file extension

	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	my $file_in = "$fs_data/v3/$lang/word/$name";

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

	print STDERR "processing synonyms\n";

	#
	# first the line-based table
	#

	# initialize an empty stem column

	my %syn_index_line_int;
	my %syn_index_line_ext;

	# for each word in the text

	for my $word (keys %word_index_line_ext)
	{
		# this array holds synonyms

		my @syn;

		# add the definitions of the stems, if any 

		if ( defined $stem_lookup{$word} )
		{

			for my $stem (@{$stem_lookup{$word}})
			{

				if (defined $syn_lookup{$stem})				
				{
					push @syn, @{$syn_lookup{$stem}};
				}
				
				# make every stem match itself
				
				if ($self_match == 1) {
					
					push @syn, $stem;
				}
			}			
		}
	
		# add the synonyms of the form, if any

		if (defined $syn_lookup{$word})
		{
			push @syn, @{$syn_lookup{$word}};
		}
		
		# flatten duplicates

		my %uniq;

		for (@syn)
		{
			$uniq{$_} = 1;
		}

		#
		# add an entry to the semantic table for each tag
		#

		for my $syn (keys %uniq)
		{ 
			for my $i (0..$#{$word_index_line_ext{$word}})
			{
				push @{$syn_index_line_int{$syn}}, ${$word_index_line_int{$word}}[$i];
				push @{$syn_index_line_ext{$syn}}, ${$word_index_line_ext{$word}}[$i];
			}
		}
	}
	
	#
	# do the same thing for the phrase table as for lines
	#

	my %syn_index_phrase_int;
	my %syn_index_phrase_ext;

	# for each word in the text

	for my $word (keys %word_index_phrase_ext) {
		
		# this array holds synonyms
		
		my @syn;
		
		# add the definitions of the stems, if any 
		
		if ( defined $stem_lookup{$word} ) {
			
			for my $stem (@{$stem_lookup{$word}}) {
				
				if (defined $syn_lookup{$stem})	{
					
					push @syn, @{$syn_lookup{$stem}};
				}
				
				# make every stem match itself
				
				if ($self_match == 1) {
					
					push @syn, $stem;
				}
			}
		}
		
		# add the synonyms of the form, if any
		
		if (defined $syn_lookup{$word}) {
			
			push @syn, @{$syn_lookup{$word}};
		}
		
		# flatten duplicates
		
		my %uniq;
		
		for (@syn) {
			
			$uniq{$_} = 1;
		}
		
		#
		# add an entry to the semantic table for each tag
		#

		for my $syn (keys %uniq) {
			
			for my $i (0..$#{$word_index_phrase_ext{$word}}) {
				
				push @{$syn_index_phrase_int{$syn}}, ${$word_index_phrase_int{$word}}[$i];
				push @{$syn_index_phrase_ext{$syn}}, ${$word_index_phrase_ext{$word}}[$i];
			}
		}
	}
	
	#
	# write the new column
	#
	
	my $file_out = "$fs_data/v3/$lang/semantic/$name";

	print STDERR "writing $file_out.index_line_int\n";
	nstore \%syn_index_line_int, "$file_out.index_line_int";

	print STDERR "writing $file_out.index_line_ext\n";
	nstore \%syn_index_line_ext, "$file_out.index_line_ext";

	print STDERR "writing $file_out.index_phrase_int\n";
	nstore \%syn_index_phrase_int, "$file_out.index_phrase_int";

	print STDERR "writing $file_out.index_phrase_ext\n";
	nstore \%syn_index_phrase_ext, "$file_out.index_phrase_ext";
}
