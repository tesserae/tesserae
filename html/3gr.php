<?php
	$lang = 'la';
	$default_t = 'vergil.georgics.part.1';	
?>








<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

		</div>

<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi . '/3gr.init.pl' ?>" method="post" ID="Form1">

				<h1>3-Gram Visualizer</h1>
				
				<p>
					View a color-coded representation of 3-gram concentrations in a text.
				</p>

				<table class="input">
					<tr>
						<th>Target:</th>
						<td>
							<select name="target_auth" onchange="populate_work('la','target')">
							</select><br />
							<select name="target_work" onchange="populate_part('la','target')">
							</select><br />
							<select name="target">
							</select>
						</td>
					</tr>
				</table>
				<table class="input">
					<tr>
						<th>N-grams to calculate:</th>
						<td>
							<select name="top">
								<option value="10" selected="selected">10</option>
								<option value="20">20</option>
								<option value="30">30</option>
								<option value="40">40</option>
								<option value="50">50</option>
								<option value="100">100</option>
								<option value="150">150</option>
								<option value="200">200</option>
							</select>							
						</td>
					</tr>
				</table>
				
				<div style="text-align:center; padding:20px;">
					<input type="submit" name="submit" value="Calculate" />
				</div>
			</form>
		</div>
		<div style="visibility:hidden">
				<select id="la_texts">
					<?php include $fs_html.'/textlist.la.r.php'; ?>
				</select>
		</div>

		<script type="text/javascript">
			populate_author('la', 'target');
			set_defaults({'target':'la'}, {'target':'vergil.georgics.part.1'});
		</script>

		<?php include "last.php"; ?>

