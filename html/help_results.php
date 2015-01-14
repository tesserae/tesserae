<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>


			</div>
<?php include "nav_help.php"; ?>
			<div id="main">
				<h1>Help</h1>

				<h2>Results Page</h2>
				<p>
					The results page has several components, the most important of which
					is the list of textual parallels.  Other components include a set of 
					options for sorting and exporting results, a pager, and session details.
				</p>
				
				<h2>Reading Results</h2>
				<p>
					The table of results has four columns.
				</p>
				
				<h3>Target Phrase</h3>
				<p>
					The line number and text of the target (alluding) phrase.  The matching 
					words are highlighted.  Click on the line number to display the target 
					phrase in context in a new window.
				</p>

				<h3>Source Phrase</h3>
				<p>
					The text of the source (alluded-to) text.  Again, clicking on the locus
					should display the phrase in context.
				</p>
								
				<h3>Matched On</h3>
				<p>
					This gives the features shared by the two phrases.  The matching features
					may not be the same as the highlighted words—for example, if the feature
					set searched on is stems, the default, then this column will list the
					dictionary headwords matched, not the specific inflected forms.  In cases
					where an inflected form is ambiguous, it may cause several possible stems
					to appear here.
				</p>
				
				<h3>Score</h3>
				<p>
					This score is a guess as to the significance of the result.  Score is 
					based on the frequency of the matching words and on the distance between
					them within each phrase.  For more information on how these are calculated,
					please look at the “Advanced Features” help page.
				</p>
				<p>
					Initial testing has shown that Tesserae's score tends to correlate roughly
					with human-perceived literary significance, but it remains a work in
					progress.  Scores may change as we continue to update the program.
				</p>
				
				<h2>Sorting</h2>

				<p>
					Adjust the options at the top of the page and click “Change Display”
					to re-sort your results without performing the search again.
				</p>

				<h3>Sort Options</h3>
				<p>
					By default, results are sorted according to location in the target text.
					You can also sort by location in the source, or by score.
				</p>
				<p>
					Change the sort order to “decreasing” when sorting by score to put the
					most significant results first.
				</p>
				
				<h2>Pages</h2>
				<p>
					By default, the table is split into “pages” of 100 results.  Choose
					more or fewer from the drop-down list and click “Change Display” to 
					change.  An abbreviated page index appears above the table.
					Selecting “all” will turn this feature off, displaying all results 
					on the same page.
				</p>
				
				<h2>Export Options</h2>
				<p>
					By default, results are displayed as an html table.  If you change 
					the “format as” drop-down, clicking the “Change Display” button will
					cause the results to be downloaded to your computer as a separate file.
				</p>
				
				<h3>CSV</h3>
				<p>
					This format is appropriate for import into a spreadsheet such as
					Microsoft Excel or OpenOffice Calc. Each result appears on a separate 
					line.  Columns are separated by commas.  Text appears within double
					quotation marks.  Newlines are Unix-style.
				</p>
				<p>
					CSV results will be sorted according to the options set when you
					click the button.
				</p>
				
				<h3>XML</h3>
				<p>
					Results are marked up in a custom XML format.  This is probably 
					only useful to advanced users who want to do their own automated
					processing of the results file.  For more information please 
					email us.
				</p>
				
				<h2>Session Details</h2>
				<p>
					This section gives a summary of the search settings which produced
					the results.  The search itself is done only once, when you click
					“Compare Texts”; these settings are not affected by subsequent changes 
					to the sort order or other aspects of results display.
				</p>
				<p>
					This information is for the most part probably not helpful to casual
					users.  It can be useful if you are saving and comparing results from
					multiple searches.  Note that the complete stop list is recorded here.
				</p>				
				
			</div>

			<?php include "last.php"; ?>


