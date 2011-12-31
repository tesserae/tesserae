	<?php include "first.php"; ?>

				<div id="nav_sub">
					<ul>
						<li><a href="<?php echo $url_html.'/index.php' ?>">Search Home</a></li>
					</ul>
				</div>
			</div>

			<div id="main">
				<h1>Methods and Instructions</h1>

				<a name="version1"></a>				
				<h2>Basic Search</h2>
				<p>
					Basic search returns two- to six-word strings which share at least two words.  
					Strings may span lines or sentences in the original poem.  Shared words must be identical 
					in form; inflection is not accounted for.
				</p>
				<p>
					A stop-list is used to prevent common words from matching.  By default, the stop-list 
					contains those forms which account for the top 20% of all words in the corpus (see 
					<a href="#frequency">below</a>).  By clicking on the "options" link at the bottom of the page, 
					you can adjust the size of the stop-list (or turn it off), and/or enter a custom list.  
					The particular stop-list used is stated at the bottom of each results list.
				</p>
				<p>
					Basic search results are not scored.
				</p>

				<a name="version2"></a>
				<h2>Version 2</h2>
				<p>
					Version 2 returns grammatical phrases that share two or more words.  Phrase boundaries 
					were determined by editorial punctuation, and may span several lines in the original poem.
				</p>
				<p>
					Version 2 matches different inflected forms of the same dictionary headword.  Thus <em>mos</em> 
					and <em>mores</em> will match.  Forms whose headword is ambiguous will match against any 
					of the possibilities.
				</p>
				<p>
					The dictionary headwords were determined using the 
					<a href="http://archimedes.mpiwg-berlin.mpg.de/arch/doc/xml-rpc.html">Archimedes Morphology Service</a>
					provided by the 
					<a href="http://archimedes2.mpiwg-berlin.mpg.de/archimedes_templates/project.htm">Archimedes Project</a>.
				</p>
				<p>
					The exclusion of stop-words is for now less fine-grained in Version 2, but it can be turned on 
					or off using the checkbox on the search page.  Results lists from Version 2 searches can be 
					very large, especially for long poems; when in doubt, it's probably best to leave the box checked.
				</p>
				<p>
					Results from Version 2 are scored based on the number of words they share, and the proximity 
					of those words within the two phrases.  The scoring system is currently under development, 
					and should be considered experimental for now.  Any feedback on which results are most helpful 
					to users would be appreciated by the developers.
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

				<a name="frequency"></a>
				<h2>Frequency</h2>
				<p>
					Word frequency was the basis for the stop-lists used by the Basic Search.  The stop-lists 
					are identified by the percentage of all tokens in the corpus which they exclude.  For example, 
					<em>et</em>, occurring 18,250 times, makes up 3% of all word forms in the corpus by itself.  
					The 10% list contains the following words: <em>et</em>, <em>in</em>, <em>non</em>, <em>nec</em>,
					<em>est</em>, <em>cum</em>, <em>si</em>, <em>ut</em>, <em>sed</em>, <em>per</em>, <em>ad</em>, 
					<em>tibi</em>, <em>quae</em>, <em>iam</em>, <em>quod</em>.  

					The 20% list includes an additional 57 words, to which the 30% list adds another 180.
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


