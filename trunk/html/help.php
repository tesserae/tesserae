	<?php include "first.php"; ?>

				<div id="nav_sub">
					<ul>
						<li><a href="<?php echo $url_html.'/index.php' ?>">Search Home</a></li>
					</ul>
				</div>
			</div>

			<div id="main">
				<h1>Instructions</h1>

				<h2>Basic Search</h2>
				<p>
					The results are pairs of lines, one from each poem, which share at least
					two words.  Shared words may not be identical in form, but share a common
					dictionary headword.  These headwords are determined using an online
					dictionary; forms matching multiple headwords will match on any of the
					possibilities.
				</p>
				<p>
					Scoring of results is an ongoing research project; any scores you see are
					experimental only, and subject to change.
				</p>
				
				<h2>Advanced Features</h2>
				
				<p>
					On this page you can adjust a number of settings which are otherwise
					set for you by default.
				</p>
				
				<h3>Units</h3>
				
				<p>
					Here you can choose the textual units which are compared.  Choices are
					verse lines (the default), grammatical phrases (determined by punctuation),
					and six-word windows.
				</p>

				<h3>Feature Set</h3>
				
				<p>
					This means the textual features which must be shared to consitute a match.
					The default is lemma, meaning two words are judged to match if they share
					a dictionary headword.  Setting this to exact form only will require 
					inflected forms to match exactly.
				</p>
				
				<h3>Exclude Features</h3>
				
				<p>
					To reduce the number of uninteresting results, you can choose to exclude
					matches with high-frequency words or stems.  By default, matches with the
					top 20 most frequent features (measured across our entire corpus) are 
					excluded.
				</p>
				
				<h2>Displaying results</h2>
				<p>
					By default, results are presented as a table in HTML format.  Changing 
					the options at the top of the page and clicking "Display Results" will 
					cause the same data to be re-sorted without performing the search again. 
					Selecting text-only output will display a plain-text version of the same table.  
					Selecting CSV or XML will automatically download the formatted file.
				</p>
				
				<h2>Methods</h2>
				
				<h3>Dictionary</h3>

				<p>
					The dictionary headwords were determined using the 
					<a href="http://archimedes.mpiwg-berlin.mpg.de/arch/doc/xml-rpc.html">Archimedes Morphology Service</a>
					provided by the 
					<a href="http://archimedes2.mpiwg-berlin.mpg.de/archimedes_templates/project.htm">Archimedes Project</a>.
				</p>

				<h3>Texts</h3>
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
			</div>

			<?php include "last.php"; ?>


