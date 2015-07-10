<?php 	$page = 'help'; ?>
<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>


			</div>
<?php include "nav_help.php"; ?>
			<div id="main">
				<h1>Getting Started</h1>
				
				<h2>Basic Search</h2>
				
				<p>
					Tesserae is a toolkit with a lot of powerful functions, but its most
					basic use is still the most popular: comparing two texts to find every place where
					they share two or more words within a single line or phrase. If you
					are studying a text and you suspect that its author makes
					use of another text, this is the fastest way to find the locations 
					where the two texts are connected. Tesserae will attempt to score the
					connections it discovers according to the likelihood that you'll consider them interesting;
					in other words, it will try to sort the deliberate allusions from the accidental
					overlaps in language.
				</p>

				<h3>Target</h3>
				<p>
					The “target” text is the text you are studying most closely.
					It is generally the alluding text, and the more recent.
				</p>
				<p>
					Choose the author, then the work, then the subsection of that work (if available).
				</p>

				<h3>Source</h3>
				<p>
					The source text is the earlier, alluded-to text. 
				</p>
				
				<h3>Compare Texts</h3>
				
				<p>
					Clicking on “Compare Texts” will initiate a default search
					for parallel language between the selected texts.
					The default settings are designed to capture the largest number of interesting
					intertexts and rank them as efficiently as possible. Most people begin with a default search,
					then come back to tweak the values which can be found under 'advanced features.' 
				</p>
				<p>
					The default search will produce pairs of phrases, one from each
					text, which share at least two words. Words are considered
					to be “shared” if they partake of a common dictionary headword or <i>lemma</i>. As of 
					Version 3.1 (July 2015), default searches include both shared-lemma and semantic matches, 
					the latter of which include synonyms, antonyms, and many compound words. 
				</p>	
				<p>Two things might result
					what corpus linguists call "Type A" errors, which in our case are matches that don't really share two words.
					First, inflected forms whose stem is ambiguous will match on any possibility.
					For example, Latin <i>bellum</i>, meaning "war," will match <i>bellae,</i>
					"beautiful ladies," because <i>bellum</i> could have been the masculine accusative from of <i>bellus</i>, meaning "beautiful."
					Second, semantic matches are based on an automatically-generated dictionary of synonyms. The 
					technology behind this process is still developing, and some of the connections it draws are erroneous.
				</p>
				<p>
					Your search may take a few moments, particularly if you
					have chosen full epics under both drop-down lists.
					Note that results for such searches often number in the
					tens of thousands.  It is usually wise to choose the target
					text as specifically as possible.
				</p>
				<p>
					If you need to search two large texts and your browser
					is timing out before the results are ready, please feel
					free to email us and we'll send you your results.
				</p>
			</div>

			<?php include "last.php"; ?>


