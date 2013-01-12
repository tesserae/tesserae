<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

			</div>


			<div id="main">
				<h1>Old Versions</h1>

				<p>
					Since the project's start in 2008, we have seen three major versions.  Both the “Basic Search” and “Advanced Search” interfaces default to Version 3.  Access to legacy versions is provided here, for those who need continuity with previous results.  For more information, see the appropriate Help page.
				</p>

				<h2><a href="<?php echo $url_html.'/v2.php'; ?>">Version 2</a></h2>

				<p>
					This was the version used to generate the majority of the data in the <em>TAPA</em> article.  The matches are between grammatical phrases, and the default feature set is lemma.
				</p>
				
				<h2><a href="<?php echo $url_html.'/v1.php'; ?>">Version 1</a></h2>
					
				<p>
					The first version of Tesserae was rather different: matches were based on a moving six-word window, and results included one-to-many and many-to-many matches.  For instructions on how to use V1 advanced features as well as some caveats about continuity, please see the Help page.
				</p>
			</div>
		
			<script language="javascript">

				var ddlsrc = document.getElementById('source');
				var ddltrg = document.getElementById('target');

				ddlsrc.options[0].selected = true;
				ddltrg.options[ddltrg.options.length-1].selected = true;

			</script>	

			<?php include "last.php"; ?>
