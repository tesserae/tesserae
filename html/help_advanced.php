<?php 	$page = 'help'; ?>
<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>


			</div>
<?php include "nav_help.php"; ?>
			<div id="main">
			
				<h1>Advanced Search</h1>
				
				<p>
				By clicking on “show advanced” on any search page, you can adjust the search settings.
				</p>
				
				<h3>Units</h3>
				
				<p>
				Choose to compare either verse lines (for poetry only) or phrases. Phrases are equivalent to sentences, except that they can be separated by semicolons as well as the usual marks of sentence punctuation. Any search involving a prose text, even if the other text is verse, will automatically search by phrase, regardless of whether “line” is selected here. The default is line.
				</p>

				<h3>Feature</h3>
				
				<p>
					Choose which textual features will be matched across texts. The default is lemma, meaning two words are judged to match if they share
					a dictionary headword.  Setting this to 'word' will require 
					inflected forms to match exactly.  
				</p>

	<table style="width:90%" align=center>
 <tr >
  <td align=left width=150><b>Selecting this feature</b>
  </td>
  <td align=left><b>Returns sets of parallels between texts where
  the matched words</b>
  </td>
 </tr>
 <tr>
  <td align=left>Exact word
  </td>
  <td align=left>are spelled exactly the same.
  </td>
 </tr>
 <tr >
  <td align=left>Lemma
  </td>
  <td align=left>have the same dictionary headwords.
  </td>
 </tr>
 <tr >
  <td align=left>Semantic match
  </td>
  <td align=left>Have a relationship of meaning, as
  determined by common words in their English dictionary definitions.
  </td>
 </tr>
 <tr >
  <td align=left>Lemma + semantic match
  </td>
  <td align=left>Have the similarities of either of
  these two features.
  </td>
 </tr>
 <tr >
  <td align=left>Sound
  </td>
  <td align=left>Share three-letter sequences, with
  matches that have higher numbers of three-letter sequences ranked more
  highly.
  </td>
 </tr>
</table><br>
				
				<h3>Number of Stop Words</h3>
				
				<p>
Choose whether to eliminate from the results the highest-frequency words, which may be inherently less interesting, and, if so, how far down the list of most frequent words to go. The list of words by frequency is generated from the sources chosen under “stoplist basis.” The stoplist is specific to the language feature chosen. If you choose exact word matching, then the search will use a list of the frequency of each exact spelling. So Latin animus and animo would each have separate entries in the list. If you choose lemma matching, the search will use a list of the frequency of each lemma, in any inflected form. So instances of animus and animo would both be counted under the lemma animus. The complete stoplist generated is printed at the bottom of each results page.The default is a stoplist of 10.
				</p>

				<h3>Stoplist Basis</h3>
				
				<p>
		Choose which texts will be used to determine frequencies for the stoplist. These can be the whole corpus for that language in Tesserae, the source text or target texts only, or the latter two combined. The default uses the whole corpus.
				</p>

				<h3>Score Basis</h3>
				
				<p>
The scoring system puts matches at the top of the results list that consist of rarer words closer together.
					
				</p>
<p>
Here you can choose how rarity is calculated for the purposes of scoring. The measurement of frequency can be based on the number of appearances of the exact form of each match word (“word”) or all the possible inflections of the word (“stem”). The default is “word.”
</p>
				<h3>Frequency Basis</h3>
				
				<p>
					Scores assigned during Tesserae search depend in part on the frequency
					of constituent matchwords. 'Frequency' here refers to the number of times a given word appears in a text or group of texts; the 'frequency basis' feature sets the contents of that corpus.
Frequency values can be based on the
					 target and source texts (the 'texts' setting) or they can reflect the appearance of a matchword in the
					corpus as a whole (the 'corpus' setting, which is the default).
				</p>
				<p>
					It is important to note that, because semantic-based matching is now incorporated
					into Tesserae searches, sometimes a matchword in the target text is not
					based on the same lemma as its corresponding matchword in the source text. For this reason, 
					the frequencies of each word in a match are considered separately. When frequency scores are
					based on 'texts,' then matchwords in the 
					target text are scored according to their frequency in the target text, and
					each corresponding matchword from the source text is scored according to its
					frequency in the source. If 'corpus' is selected instead, each word is examined according
					to its rate of appearance in the corpus of texts in the appropriate language.
				</p>	




				<h3>Maximum Distance</h3>
				
				<p>
					This allows you to exclude matches where the matching words are
					too far from each other to be relevant.  Distance is measured
					inclusively in words: two adjacent words thus have a distance of 2.
					Two words with one between them have a distance of 3.
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


