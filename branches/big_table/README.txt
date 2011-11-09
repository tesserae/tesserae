Big Table prototype

### contents of this directory ###

I'm drawing on some pieces of the current Tesserae, including its directory
structure.  You should find here the following sub-directories, as on billie:

	./perl  	the scripts
	./texts 	the plain texts, subdivided into latin and greek
	./data  	parsed texts stored as binaries
	./xsl   	xsl stylesheets used to turn xml results into html

I'm borrowing the following files straight from the current version, or with
only slight modification:

	perl/TessSystemVars.pm     	
	  - a module that exports shared functions and variables

	perl/configure.pl
	  - a script that adjusts paths in the scripts to the local installation

	xsl/html-header-footer.xsl 	
	  - a stylesheet that creates the common parts of results pages

	xsl/target.xsl
	  - a stylesheet that formats xml results as an html table, 
	    sorted by location in the target text
	
	xsl/score.xsl
	  - a stylesheet that sorts by score

	texts/la/*
	  - the plain text versions of tesserae texts

The new scripts are these:

	perl/add_column.pl
	  - reads a plain text and creates a new column for that 
	    text in the words-based table

	perl/stems_add_column.pl
	  - reads a text's column in the words table and creates 
	    an analagous column in the stems table
	
	perl/big_table_frequencies.pl
	  - adds the token counts created by add_column.pl for each
	    separate file and creates word and stem counts for the
	    whole corpus.

	perl/read_table
	  - reads two columns from a table and returns all the
	    parallels between those texts in our current xml format.

There are some other scripts that I haven't done much with; you can 
ignore them.

### quick start ###

On my computer, the following set of steps works (working from 
the directory where this README is found):

Installation:

	perl perl/configure.pl

Adding the texts in the latin texts directory to a new table:

	perl perl/add_column.pl	texts/la/*
	perl perl/stems_add_column.pl texts/la/*

Generating frequency statistics for latin:

	perl perl/big_table_frequencies.pl la

Getting results:

	perl perl/read_table.pl 

By default the last step will dump xml output to the termial.  
On my Mac, I use the program xsltproc to convert the xml to html 
using the stylesheets in the xsl directory:

	perl perl/read_table.pl > results.xml
	xsltproc xsl/target.xsl results.xml > results.html

### options ###

The add_columns scripts parse the text into both phrases and lines,
and index both words and stems.  By default, perl/read_table.pl searches
for parallel phrases in vergil.aeneid and lucan.bc.1 based on stems.

If you parse other plain text (.tess) files, or want to search on words
or lines, use command line arguments to read_table.pl:

	perl perl/read_table.pl [--line] [--word] [--session=SESSION] [TARGET SOURCE]

where TARGET and SOURCE are the names of previously parsed texts, minus
the path and .tess extension; and SESSION is an id for the header of the
xml file, simulating the usage on billie.

### general theory ###

I'm sorry, this is underdeveloped.  I'm sure Xia can probably tell us 
more about what's going on / should go on than I can explain.

Basically, I make an index arranged by word (or stem, in the stem table).
For each word there's a list of phrases (or lines, in the lines tables) 
that contain that word, and a second, parallel list of the word's 
locations within each of those phrases.  Then there's a 2-dimensional 
array containing every phrase and every word in it.

So for a given word, you can get a list of co-ordinates where it's found:
(phrase id, position in phrase).  Then you can look up those co-ordinates 
in the array of phrases and find the word there.

To compare two texts, we get the list of all words in one (i.e. the keys 
to the index).  For each one that's also in the second text but not on 
the stop list, we get the list of phrases where it's found in the first 
text.

For each of those, we create a match to each of the phrases in the second 
text where the same word is found.

At the end, we have an array of matches organized by phrase number in the 
first text.

Then we return all matches that include at least two distinct words in 
each text.

There are some kind of ranting comments in the code, especially in 
perl/read_table.pl.

I'll try to write this up a little more clearly next week.

Chris Forstall
