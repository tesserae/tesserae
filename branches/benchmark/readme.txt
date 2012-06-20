
Step 1: Align the Tess V3 phrases with the quoted text in the CSV parallels.  

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

2. Calculate inverse document frequency scores

This script taps into the local Tesserae installation and extracts word-frequency information for all the texts there.  It's necessary for the metrics script in step 5.

	tess-idf.pl
	
3. Measure a bunch of stuff

This one script should measure all the things we know how to measure.  I named it after David because he's the prospective client.

	david_johnson.pl
	
Each metric or group of metrics has its own subroutine.  They need better documentation.  In particular, we need a way of keeping the header up-to-date.

To run the script, just do:

	$ perl david_johnson.pl > some.file.csv
	
