	<?php include "first.php"; ?>

				<div id="nav_sub">
					<ul>
						<li><a href="<?php echo $url_html.'/index.php' ?>">Search Home</a></li>
					</ul>
				</div>
			</div>

			<div id="main">
				<h1>Instructions</h1>

				<a name="version1"></a>			
					
				<h2>Version 1</h2>
				<h3>Basic Search</h3>
				<p>
					This is our earliest product, the Version 1 search.
					The results are two- to six-word strings which share at least two words.  
					Strings may bridge lines or sentences in the original poem.  Shared words 
					must be identical in form; inflection is not accounted for.
				</p>
				<p>
					Basic search results are not scored.
				</p>
				
				<h3>V1 Advanced Features</h3>
				
				<p>
					On this page you can adjust the number of stop words used in the V1 search.
					By default, the basic search excludes matches with the top 10 most frequent
					words in our corpus.  By selecting a different value from the drop-down
					menu, you can increase the size of this list, or choose to display all
					results.
				</p>
				<p>
					You can create your own custom stop list by entering as many words as you
					like, separated by spaces, in the text box.  If you select a pre-defined
					stop list and enter your own words, the two lists will be combined.
				</p>

				<a name="version2"></a>
				<h2>Version 2</h2>
				<p>
					Version 2 returns grammatical phrases that share two or more words.  
					Phrase boundaries were determined by editorial punctuation, and may span
					several lines in the original poem.
				</p>
				<p>
					Version 2 matches different inflected forms of the same dictionary headword.
					Thus <em>mos</em> and <em>mores</em> will match.  Forms whose headword is
					ambiguous will match against any of the possibilities.
				</p>
				<p>
					The dictionary headwords were determined using the 
					<a href="http://archimedes.mpiwg-berlin.mpg.de/arch/doc/xml-rpc.html">Archimedes Morphology Service</a>
					provided by the 
					<a href="http://archimedes2.mpiwg-berlin.mpg.de/archimedes_templates/project.htm">Archimedes Project</a>.
				</p>
				<p>
					Version 2 search has a built-in stoplist consisting of the top 10 most
					frequent headwords.  Any word form which could possibly be derived from
					one of these is excluded from the results.
				</p>
				<p>
					Results from Version 2 are scored based on the number of words they share,
					and the proximity of those words within the two phrases.  
					The scoring system is currently under development, and should be considered
					experimental for now.  Any feedback on which results are most helpful 
					to users would be appreciated by the developers.
				</p>
				<p>
					There are currently no advanced settings for Version 2.
				</p>


				<a name="texts"></a>
				<h2>Texts</h2>
				<p>
					The Latin texts used were retrieved from the public domain works at 
					<a href="http://thelatinlibrary.com/">TheLatinLibrary.com</a>, and from the 
					<a href="http://www.perseus.tufts.edu">Perseus Digital Library</a>. 

					You can find specific information about the sources of the texts
					<a href="<?php echo $url_html.'/sources.php'; ?>">here</a>.  

					The texts' original HTML or XML markup was edited to remove extraneous tags and to clarify 
					line numbering.  Their Latin content was not altered, although editorial additions originally 
					appearing in angle-braces may have been accidentally removed or may appear without the braces.  
					You can view and download the text files used in our searches <a href="<?php echo $url_text; ?>">here</a>.
				</p>

				<a name="display"></a>
				<h2>Displaying results</h2>
				<p>
					By default, results are presented as a table in HTML format.  Changing the options at the top 
					of the page and clicking "Display Results" will cause the same data to be re-sorted without performing 
					the search again. Selecting text-only output will display a plain-text version of the same table.  
					Selecting CSV or XML will automatically download the formatted file.
				</p>
				<p>
					Version 1 results group together multiple matching lines.  When sorting results by Target, each line 
					in the target text is listed once, with all lines from the source that match it.  When sorting 
					by Source, each line from the source text is listed separately with all matching lines from the 
					target text.  This is meant to facilitate reading through one text or the other line by line.  
					When sorting by matching words, all matching lines from either text are listed together.
				</p>
				<p>
					Version 2 results list each parallel on a separate line.  Thus, if the first line of Lucan's 
					<em>Pharsalia</em> matches several different lines in Vergil's <em>Aeneid</em>, it will appear 
					several times in succession in the results, each time with one match from Vergil.
				</p> 
			</div>

			<?php include "last.php"; ?>


