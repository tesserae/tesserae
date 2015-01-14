<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>


			</div>
<?php include "nav_help.php"; ?>
			<div id="main">
				<h1>Help</h1>
				
				<h2>Advanced Search</h2>
				
				<p>
					On this page you can adjust a number of settings which are otherwise
					set for you by default.
				</p>
				
				<h3>Units</h3>
				
				<p>
					Here you can choose the textual units which are compared.  Choices are
					verse lines or grammatical phrases.  Phrases are delimited for this
					purpose by editorial punctuation, and parsed automatically.
				</p>

				<h3>Feature Set</h3>
				
				<p>
					This means the textual features which must be shared to consitute a match.
					The default is lemma, meaning two words are judged to match if they share
					a dictionary headword.  Setting this to exact form only will require 
					inflected forms to match exactly.  
				</p>
				<p>
					Lemma + synonyms is an experimental option which attempts to match
					forms not only to their own dictionary headword but also to headwords
					having related meanings.  The relationship between headwords was
					determined automatically by parsing of a Latin-English dictionary;
					this procedure and the dictionary used are under revision and may
					change.
				</p>
				
				<h3>Number of Stop Words</h3>
				
				<p>
					To reduce the number of uninteresting results, you can choose to exclude
					matches with high-frequency features.  The stoplist is determined for
					the selected feature set by ranking features within the stoplist basis 
					(see below) according to frequency, and taking the top N items from
					this list.  The default stoplist size for a Basic Search is 10.
				</p>
				<p>
					Note that the stop list is feature-set specific.  If your feature set
					is exact-form only, then inflected forms are used; if the feature set
					is stems or stems + synonyms, then headwords are used.  The complete
					stoplist used in a given search is printed at the bottom of each 
					results page.
				</p>
					
				<h3>Stoplist Basis</h3>
				
				<p>
					By default, the ranked list of features from which the stoplist is
					drawn is calculated across the entire Tesserae corpus.  This can
					be changed to use features from the target text only, from the source
					only, or from just the target and source combined.
				</p>
				<p>
					For example, in a default search, matches against the top 10 most
					frequent headwords in the entire corpus will be ignored.  Some of
					these words may be less frequent in the particular texts compared.
					If you set the stoplist basis to “target,” then matches against 
					the top 10 most frequent headwords in the target text will be ignored.
				</p>

				<h3>Maximum Distance</h3>
				
				<p>
					This allows you to exclude matches where the matching words are
					too far from each other to be relevant.  Distance is measured
					inclusively in words: two adjacent words thus have a distance of 2.
					Two words with one between them have a distance of 3.
				</p>
				<p>
					<b>Note that the way this distance is calculated has recently
					changed.</b>  If your results seem more inclusive compared to Fall
					2012 (and you don't want this) try setting max distance lower.
				</p>
				<p>
					In a Basic Search, there is no max distance limit.
				</p>

				<h3>Distance Metric</h3>
				
				<p>
					There are two principal modes for calculating the max distance
					described above.  <b>Frequency</b>, the default, attempts to zero 
					in on the most relevant words in an allusion, measuring the distance 
					only between the phrase's two most infrequent words.  <b>Span</b> 
					considers the greatest distance between any two matching words in a phrase.  
				</p>
				<p>
					In addition, the max distance threshold can be applied to the
					sum of the distances of the target and source phrases, or only
					to one or the other.  Note that this will halve the total
					distance for each parallel, causing scores to be higher.
				</p>
				
				<h3>Drop Scores Below</h3>
				
				<p>
					This will exclude results based on the score automatically
					assigned by Tesserae.  Testing of the scoring system is ongoing,
					but preliminary results show that parallels scoring 6 or above
 					are more likely to be interesting.  The default is no cutoff.
				</p>
				
			</div>

			<?php include "last.php"; ?>


