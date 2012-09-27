How I deal with the semantic cache
--Chris Forstall

1. read the whole dictionary and cache the entries with storable

   $ perl read-full-lewis.pl [FILE]

By default, this uses XML::LibXML to parse the whole lewis-short.xml
dictionary file and save the entries in hashes:

cache-def

 - this hash stores everything that was in italics in an entry.
   the keys are dictionary headwords; the values are anonymous
   arrays of things that were between <hi rend="ital"></hi> tags.

cache-text

 - this hash stores the full text of each entry as one string.
   the keys are headwords, the values are the entries.How I deal with the semantic cache
--Chris Forstall

1. read the whole dictionary and cache the entries with storable

   $ perl read-full-lewis.pl [FILE]

By default, this uses XML::LibXML to parse the whole lewis-short.xml
dictionary file and save the entries in hashes:

   cache-def

 - this hash stores everything that was in italics in an entry.
   the keys are dictionary headwords; the values are anonymous
   arrays of things that were between <hi rend="ital"></hi> tags.

   cache-text

 - this hash stores the full text of each entry as one string.
   the keys are headwords, the values are the entries.

Note that the headwords are standardized as follows:

 - everything but letters a-z is removed
 - all entries are converted to lowercase
 - 'j' is replaced with 'i' everywhere

Where these changes make two different headwords look alike, 
their entries are merged:

 - the lists of definitions are combined
 - the full-text entries are concatenated

2. read the cached entries and create a frequency chart for
	definitions

	$ perl create-stoplist.pl

The output is a text file:

   count-def.txt
	
 - a list of all the unique definitions, with the number of headwords
   under which each appears.  Some "definitions" are very common; 
   most of these aren't definitions at all, but dictionary paratext 
   that was italicized, things like parts of speech.  For example, 
   "inf." seems to be a definition of 949 different headwords.

3. Examine by hand the file count-def and remove any definitions you
   don't actually want on the stoplist.  I do it this way:

	$ awk '{ if ($1>15) { print $0 }}' count-def.txt > stoplist-defs.txt
	
That gives me a new file with only the definitions shared by at least 16
different headwords, and reduces the number of definitions I need to
examine from 116,575 to 813.  Anything that I miss will only affect 15
words, which is a number I can live with.  But you can do it differently.

Then I go over the file with a text editor and *delete* lines I think
are *real definitions*.  NB: This is a stoplist, so anything on the list
will be excluded from the final form of the dictionary!

For example, these two lines appear in the file I created:

  17	fiery
  17	num. distr. adj.

I'll delete the top line, since I do want words to match on the English
definition "fiery", but I'll leave the second one in the stoplist.

4. Use the definitions stoplist created in steps 2-3 to remove selected
	definitions from the definitions cache.

	$ perl apply-stoplist.pl FILE

   where in my case FILE is called stoplist-defs.txt (see #3).

The script apply-stoplist.pl reads in the cache of definitions.
This is a hash whose keys are headwords; each value is a list of
definitions for that headword.

Now we turn that inside out, creating a new hash whose keys are
definitions, and each value is a list of headwords under which
that definition appears.

Then we go through the stoplist specified by FILE and delete any
keys that match a line in the stoplist.  At one blow, that removes
the definition from any entry in which it appeared in the original
hash.  Then we invert the new hash again to rebuild the original.
Any headword in the original whose only/every definition was included
in the stoplist will not come back.

The new, trimmer hash is saved, overwriting cache-def.

5. Look for places where one dictionary entry redirects you to an
other one, rather than defining the headword itself.

	$ perl follow-redirects.pl

This script loads cache-text, a hash of the full text of dictionary
entries rather than just italicized definitions.

The keys to this hash represent every headword in the dictionary,
including many which for various reasons are not in our hash of
definitions.

Check keys in this hash for which there is no key in the definitions
hash.  If the text of the dictionary entry has any one of a series
of regular expressions known to indicate a redirect, then determine
the headword to which we're redirected and see whether it has any 
definition.  If so, copy its definition(s) to the original headword's
entry in the definitions hash.

This program reports the number of headwords that get definitions
from redirects where they had none before.  Apparently, some entries
redirect you to other entries which themselves have only a redirection.
  - that means that if you run this program twice, you get new hits.
  - I usually run it several times, until the number of previously
    undefined words that get new definitions is 0.

6. Create a frequency chart for all the English words in the dictionary
	entries.  This will be used later to weight semantic matches.

	$ perl engl_word_count.pl

This script counts every word occurring in every definition.  It only 
counts strings of letters a-z, and it converts everything to lowercase.

The counts are stored in a hash, where keys are terms and values are 
the number of times they occur.  This is ready to be used by the scoring
system of tesserae.

The output is a binary saved with Storable:

	count-english

Note: you might want to do this step before #5, in order to avoid
counting words in redirected entries multiple times.

7. (Optional) Install to tesserae.

	$ cp cache-def    	TESS_DATA/common/la.semantic.cache
	$ cp count-english	TESS_DATA/common/la.semantic.count

where TESS_DATA is the path to the tesserae data directory.

