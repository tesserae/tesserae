			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

			</div>


			<div id="main">
				<h1>Experimental Versions</h1>

				<p>
					Here you can try out some new searches we're still testing.  We would appreciate any feedback you have.  Caution: results may not be very stable.
				</p>

				<h2><a href="<?php echo $url_html.'/grc_table.php'; ?>">Greek Search</a></h2>

				<p>
					This uses the same Version 3 algorithm as the <a href="<?php echo
					$url_html."/index.php"; ?>">Basic</a> and <a href="<?php echo
					$url_html."/index.php"; ?>">Advanced</a> Latin searches.
				</p>
				<p>
					So far, the only texts available are Homer <em>Iliad</em> and Apollonius
					<em>Argonautica</em>.  These results have not been tested.
				</p>
				
				<h2><a href="<?php echo $url_html.'/full-text.php'; ?>">Full-Text Display</a></h2>
					
				<p>
					We're currently testing new ways of displaying results.  This performs
					the default <a href="<?php echo $url_html."/index.php"; ?>">Basic Search</a>,
					but displays the full text of the Target work with references to the Source
					work highlighted in red.
				</p>
			</div>
		
			<script language="javascript">

				var ddlsrc = document.getElementById('source');
				var ddltrg = document.getElementById('target');

				ddlsrc.options[0].selected = true;
				ddltrg.options[ddltrg.options.length-1].selected = true;

			</script>	

			<?php include "last.php"; ?>
