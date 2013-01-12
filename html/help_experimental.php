<?php include "first.php"; ?>
<?php include "nav_help.php"; ?>

			</div>

			<div id="main">
				<h1>Help</h1>
				
				<h2>Experimental Search Tools</h2>
				
				<p>
					These searches are still in development.  They may change without notice,
					perform unpredictably, or include undocumented features.  If you like
					anything you see here, please let us know so that we can make its
					further development and inclusion into the main program a priority.
				</p>
				
				<h2>Multi-text Search</h2>
				
				<p>
					This search tool allows you, in addition to performing an Advanced search
					for parallels between a Target and Source text, to check the results against
					each of the other texts in our Latin corpus.  Next to each parallel will be
					listed all the additional loci in the corpus with which it shares two or
					more words.
				</p>
				<p>
					Enter your search criteria as in an Advanced Search.  Then choose from the
					list of texts at the bottom of the page those against which you want to
					cross-check your results.  Note that checking all texts takes some time.
					If you want most, but not all, boxes checked, you may use the "Select All"
					first and then individually un-check texts you don't want to include.
				</p>
				
				<h2>Full-Text Display</h2>
				
				<p>
					This offers all the same options as the Advanced Search, but displays
					the results differently.  Rather than listing parallels one by one,
					the full text of both the source and target are displayed, with matching
					words from all parallels highlighted.
				</p>
				<p>
					Hover over highlighted words in either text to see a list of corresponding
					phrases and loci in the other text.
				</p>
				<p>
					If you are a user with suggestions on what features would be useful to
					you in this interface, please send us an email.  Note that this display
					uses HTML frames and may not work equally well with all browsers.
				</p>
				
				<h2>Lucan-Vergil Benchmark Test</h2>
				
				<p>
					This tool is a bit unwieldy, but can be very useful in understanding
					what sort of results different settings are likely to produce.
					The interface allows you to set the options of an Advanced Search,
					but limited to phrase-based matching between Lucan's <em>Civil War</em>
					Book 1 and Vergil's <em>Aeneid</em>.
				</p>
				<p>
					The results of your real-time search are then automatically compared
					against our 3,300 parallel benchmark set.  This set is composed of
					parallels returned by previous versions of Tesserae as well as some
					gleaned from professional commentaries on Lucan.  Each parallel has
					been hand-inspected by human readers and given a rank, or “Type” 
					according to its perceived literary significance, roughly on the
					following scheme:
				</p>
				
				<table style="margin-left:9em">
					<tr>
						<th>5</th>
						<td>More-significant allusion</td>
					</tr>
					<tr>
						<th>4</th>
						<td>Less-significant allusion</td>
						</td>
					</tr>
					<tr>
						<th>3</th>
						<td>Genre-level language reuse without specific allusion</td>
					</tr>
					<tr>
						<th>2</th>
						<td>Non-literary language reuse</td>
					</tr>
					<tr>
						<th>1</th>
						<td>Error</td>
					</tr>
				</table>
				
				
				<p>
					Of the results of your search, only those which occur in the 
					benchmark set are displayed here.  In addition to the usual columns,
					an additional column gives the human-assigned Type for each parallel,
					and another indicates which if any of the professional commentaries
					noted the allusion.  The following abbreviations are used:
				</p>

				<table style="margin-left:9em">
					<tr>
						<th>H</th>
						<td>Heitland and Haskins (1887)</td>
					</tr>
					<tr>
						<th>TB</th>
						<td>Thompson and Bruère (1968)
						</td>
					</tr>
					<tr>
						<th>V</th>
						<td>Viansino (1995)</td>
					</tr>
					<tr>
						<th>R</th>
						<td>Roche (2009)</td>
					</tr>
				</table>

				<p>
					For a detailed guide to the parallel types and full bibliographic
					information on the commentaries used, please see the 
					<a href="<?php echo $url_html.'/lucan-vergil.php' ?>">
					description of our Lucan-Vergil test</a> under the “Research” 
					section of our site.
				</p>

				<p>
					Above the list of results, you will find a summary panel showing
					for each type what portion of the benchmark set your search 
 					returned, as well as what portion of all commentator-noted parallels
					were included.
				</p>
				
				<p>
					By default, results are sorted in descending order by score.
				</p>

				<h2>Old Versions</h2>
				
				<p>
					The current version of Tesserae, V3, is significantly different from
					former versions.  While we continue to offer access to versions 1 and 2,
					maintaining online support for these systems is not currently a 
					priority.
				</p>
				<p>
					If you have questions about their use, please feel free to email us,
					but we encourage all new users to work with V3.
				</p>
				
				<h3>Version 2</h3>
				
				<p>
					Version 2 returns results in much the same format as Version 3, but
					uses a significantly different search algorithm.  Subsequent testing
					has revealed that a certain proportion of matches meeting the criteria
					of sharing two or more headwords were at times dropped from
					Version 2 results.  Thus, older results may no longer agree with current
					V2 results.
				</p>
				<p>
					For those interested in reproducing the results reported in our 
					<em>TAPA</em> or <em>LLC</em> articles, we maintain archival copies 
					of older databases.  Please email us for more information.
				</p>
				
				<h3>Version 1</h3>
				
				<p>
					Version 1 performed a significantly different search than more recent
					versions.  Here, the unit of comparison was neither the line nor the
					grammatical phrase, but any string of up to six words.  In addition,
					matches were not limited to two-phrase pairs, but included one-to-many
					and many-to-many matching.
				</p>
				<p>
					While this format is no longer supported, we would be interested to
					hear from former users who find some value in it.  Perhaps useful
					features could be incorporated into a future Version 4.
				</p>

			</div>

			<?php include "last.php"; ?>


