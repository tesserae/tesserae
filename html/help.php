<?php 	$page = 'help'; ?>
<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>


			</div>
<?php include "nav_help.php"; ?>
			<div id="main">
				<h1>Basic Search</h1>
				
				
				<p>
					The basic search compares two texts to find every place where they share two or more words within a single line or phrase. Shared words are those that have a common lemma or are considere semantically related, with the latter category including but not limited to synonyms and antonyms.
				</p>

				<h3>Target and Source</h3>
				<p>
					The “target” text is the text you are studying most closely.
					It is generally the alluding text, and the more recent. The search is bidirectional, so the choice of which text is the target and which the source has no influence on the search. In the display of results, however, phrases from the target text will appear in the left column, those from the source on the right.
				</p>

				<h3>Compare Texts</h3>
				
				<p>
					Clicking on “Compare Texts” will initiate a default search
					for parallel language between the selected texts.
					The default settings are designed to capture the largest number of interesting
					intertexts and rank them as efficiently as possible. 
					To customize the search parameters, click on the words “advanced features” and see the relevant help page.
				</p>
				<p>
					The default search will produce pairs of phrases, one from each
					text, which share at least two words. Words are considered
					to be “shared” if they partake of a common dictionary headword or <i>lemma</i>. As of 
					Version 3.1 (July 2015), default searches include both shared-lemma and semantic matches, 
					the latter of which include synonyms, antonyms, and many compound words. 
				</p>	
				
				<h3>Limitations</h3>
				
				<p>The search uses automatic rules on the best available data, but has some known limitations. Lemma search overmatches because it does not distinguish between homographs. Latin <i>bellum</i>, meaning "war," will match <i>bellae,</i>
					"beautiful ladies," because <i>bellum</i> could have been the masculine accusative from of <i>bellus</i>, meaning "beautiful."
					Semantic matches are based on an automatically-generated dictionary of related words. Experiments have shown that the large majority of these matches are semantically related in a broad sense, but the search still returns a signifiant percentage of minimally related or unrelated words.
				</p>
				<p>
Searches on large full texts can take a few moments to process. You can speed results by choosing to compare parts of large works rather than whole works.
				</p>

			</div>

			<?php include "last.php"; ?>


