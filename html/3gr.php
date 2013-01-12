<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi . '/3gr.init.pl' ?>" method="post" ID="Form1">

				<h1>3-Gram Visualizer</h1>
				
				<p>
					View a color-coded representation of 3-gram concentrations in a text.
				</p>

				<table class="input">
					<tr>
						<td><span class="h2">Target:</span></td>
						<td>
							<select name="target">
								<?php include $fs_html.'/textlist.la.r.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Unit:</span></td>
						<td>
							<select name="unit">
								<option value="line">line</option>
								<option value="phrase" disabled="disabled">phrase</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Number of n-grams to calculate:</span></td>
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
				
				<input type="submit" name="submit" value="Compare Texts" />
			</form>
		</div>

		<?php include "last.php"; ?>

