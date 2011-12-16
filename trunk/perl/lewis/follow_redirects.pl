#
# follow_redirects.pl
#
# look through the hashes created by read-full-lewis.pl
# - try to discover entries that just redirect to other
#   headwords instead of giving a definition

use lib '/Users/chris/Desktop/tesserae/perl';	# PERL_PATH

use strict;
use warnings;

use TessSystemVars;
use Storable qw(nstore retrieve);

my $file_def = shift @ARGV || "$fs_data/common/la.semantic.cache";
my $file_text = shift @ARGV || "$fs_data/common/lewis.text.cache";

print STDERR "reading $file_text\n";
my %text	=   %{ retrieve("$file_text") };

print STDERR scalar(keys %text) . " forms\n";


print STDERR "reading $file_def\n";
my %def 	= 	%{ retrieve("$file_def")  };

print STDERR scalar (keys %def) . " defined\n\n";

#
# follow redirects
# 

print STDERR "following redirects\n";

my @undef;
my @redir;
my @redef;

for my $key (keys %text)
{

	# don't bother for entries that already have a definition
	#
	# NB: you can comment out this line to do use redirects for
	# all entries, but be careful -- I'm used to running this
	# program multiple times to catch redirects to redirects;
	# if you do this for defined entries as well, you'll double
	# up definitions that you already got on previous passes.

	next if (defined $def{$key});

	# check for any of the following regular expressions, 
	# which indicate a redirect
		
	if (	$text{$key} =~ /v\. (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /Part. of (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /Part., from (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /P. a. of (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /P. a., from (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /v. a. for (?:\d\. )?([A-Za-z]+-?)/ ||
			$text{$key} =~ /= (?:\d\. )?([A-Za-z]+-?), q. v./ )
	{

		# the entry to which we're redirected

		my $redirect = $1;

		# count the number of redirects
	
		push @redir, $key;

		# sometimes the redirection is of the form praef-
		# where we're supposed to understand that the current
		# headword has a prefix for which we should substitute
		# an alternate form, $praef.

		# the best way I can deal with this right now is to
		# assume that the two forms of the prefix have the same
		# number of chars and begin at the beginning of the word
		# then just subtitute one for the other
	
		if ($redirect =~ /([A-Za-z]+)-/)
		{
			my $praef = $1;
			my $redirect = $key;
		
			$redirect =~ s/[^a-z]//ig;
		
			substr($redirect, 0, length($praef), $praef);
		}

		# does the headword to which we're redirected actually
		# have a definition itself?  many don't, it seems.
	
		if (defined $def{$redirect})
		{
			
			# if the redirect points us to a definition where
			# we had none before, make a note of it

			if ( ! defined $def{$key} )
			{
				push @redef, $key;
			}

			# add all the definitions under the new headword
			# to the entry of the original one
	
			push @{$def{$key}}, @{$def{$redirect}};
		}
	}

	# if the headword remains undefined, count it

	if ( ! defined $def{$key} ) { push @undef, $key }
}

# some statistics

print STDERR scalar(@redir) . " redirects\n";
print STDERR scalar(@redef) . " previously undefined now have a definition\n";
print STDERR scalar(@undef) . " still undefined\n";

# overwrite the cache with the new definitions hash

nstore \%def, $file_def;

# print a list of all the headwords with no definition

for (@undef)
{
	print "$_\n";
}
