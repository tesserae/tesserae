Some notes on the perl scripts used in the large-scale score test

Step 1: Texts/Scores

The texts I used were copied from the current Tesserae corpus.

	lucan.pharsalia.part.1.tess 
	vergil.aeneid.tess
	
The benchmark human scores are from Sarah Jacobson's spreadsheet, "All Tesserae and Commentators.xls."  According to the notes there, the sheet contains combined parallels from Tesserae V1, V2, and four commentators.  The Tesserae data was from September 2010.

I extracted the relevant columns and saved them as a CSV.  There might be some serious errors in the data as a result of the trip from HTML table through Excel spreadsheet to plain text.  Two major classes of errors we've noticed in the past are (1) missing spaces/newlines in the quoted text and (2) trailing zeros dropped from Aeneid line numbers.

I deleted a couple of entries.  These were transcriptions of commentators' parallels, where there was no specific verbal similarity and no specific phrase where the allusion was located.  We should look at a better way of handling this in the future.

Step 2: Prepare as Tesserae binaries

The texts were prepared with a pared-down version of add_column.pl from the current Tesserae code, which I called

	phrase_chopper.pl

This program reads a text and produces binary files in the usual Tesserae format, saved in the directory

	data/

To do the Lucan-Vergil benchmark, run the script like this:

	$ perl phrase_chopper.pl lucan.pharsalia.part.1.tess vergil.aeneid.tess

Step 3: Align the phrase_chopper (i.e. Tess V3) phrases with the quoted text in the CSV parallels.  

Ideally, we should be able to locate the phrases referred to in the CSV by both locus and text.  I wrote a script to do this, called

	check-phrase.pl
	
It spits out some debugging data, depending on what I'm trying to fix.  I think right now it displays information about phrases that seem to align very poorly.  This should be ignored unless you spend some time looking at the script to see what it's doing.

The real product of this script is a Storable binary containing the aligned records:

	data/rec.cache
	
This contains an array of records corresponding to the parallels originally in the CSV, but now with V3-confirmed text.  Each element of the array is a hash like this:

	{
		AEN_BOOK	=>	$int,	# the book number
		AEN_LINE	=>	$int,	# the line number
		AEN_PHRASE	=>	@str,	# an array of words
		AEN_TXT  	=>	$str,	# the phrase as a string

		BC_*				# all the above but for Lucan
		
		SCORE		=>	$int	# the human assigned score
	}

4. Calculate inverse document frequency scores

This script taps into the local Tesserae installation and extracts word-frequency information for all the texts there.  It's necessary for the metrics script in step 5.

	tess-idf.pl
	
5. Measure a bunch of stuff

This one script should measure all the things we know how to measure.  I named it after David because he's the prospective client.

	david_johnson.pl
	
Each metric or group of metrics has its own subroutine.  They need better documentation.  In particular, we need a way of keeping the header up-to-date.

To run the script, just do:

	$ perl david_johnson.pl > some.file.csv
	
