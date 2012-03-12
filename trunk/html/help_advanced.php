	<?php include "first.php"; ?>

	<?php include "nav_help.php"; ?>

			</div>

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
					verse lines (the default) or grammatical phrases (determined by punctuation).
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
								
			</div>

			<?php include "last.php"; ?>


