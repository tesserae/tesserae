			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

			</div>


			<div id="main">
				<h1>Experimental Versions</h1>

				<p>
					Here you can try out some new searches we're still testing.  We would appreciate any feedback you have.  Caution: results may not be very stable.
				</p>

				<h2><a href="<?php echo $url_html.'/multi-text.php'; ?>">Multi-text search</a></h2>
					
				<p>
					Cross-references discovered parallels against the rest of the corpus.
				</p>
				
				<h2><a href="<?php echo $url_html.'/full-text.php'; ?>">Full-Text Display</a></h2>
					
				<p>
					Displays the full text of the poems with references highlighted in red.
				</p>

				<h2><a href="<?php echo $url_html.'/en_table.php'; ?>">English Search</a></h2>

				<p>
					Search a limited number of English texts.  Currently supports exact-match only.
				</p>
				
				<h2><a href="<?php echo $url_cgi.'/check-recall.pl'; ?>">Lucan-Vergil Benchmark Test</a></h2>

				<p>
					Allows you to perform a search of Lucan's Pharsalia Book 1 against Vergil's Aeneid,
					and compares the results against our 3000-parallel benchmark set.
				</p>

			</div>
		
			<script language="javascript">

				var ddlsrc = document.getElementById('source');
				var ddltrg = document.getElementById('target');

				ddlsrc.options[0].selected = true;
				ddltrg.options[ddltrg.options.length-1].selected = true;

			</script>	

			<?php include "last.php"; ?>
