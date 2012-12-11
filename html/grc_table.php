		<?php include "first.php"; ?>
		
		<?php include "nav_search.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
				
				<h1>Greek Search</h1>
				
				<p>
					This is the prototype for our forthcoming Greek search.  Texts will be very limited for the time being.
				</p>
				<p>
						These results have not been tested.  If you notice anything interesting (or broken), please let us know.
				</p>
				
				<table class = "input">
					<tr>
						<td><span class="h2">Source:</span></td>
						<td>
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.grc.l.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Target:</span></td>
						<td>
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.grc.r.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Unit:</span></td>
						<td>
							<select name="unit">
								<option value="line">line</option>
								<option value="phrase">phrase</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Feature:</span></td>
						<td>
							<select name="feature">
								<option value="word">exact form only</option>
								<option value="stem" selected="selected">lemma</option>
								<option value="syn" disabled="disabled">lemma + synonyms</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Number of stop words:</span></td>
						<td>
							<select name="stopwords">
								<option value="0">0</option>
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
					<tr>
						<td><span class="h2">Stoplist basis:</span></td>
						<td>
							<select name="stbasis">
								<option value="corpus">corpus</option>
								<option value="target">target</option>
								<option value="source">source</option>
								<option value="both">target + source</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Maximum distance:</span></td>
						<td>
							<select name="dist">
								<option value="999" selected="selected">no max</option>
								<option value="5">5 words</option>
								<option value="10">10 words</option>
								<option value="20">20 words</option>
								<option value="30">30 words</option>
								<option value="40">40 words</option>
								<option value="50">50 words</option>
							</select>							
						</td>
					</tr>
					<tr>
						<td><span class="h2">Distance metric:</span></td>
						<td>
							<select name="dibasis">
								<option value="span">span</option>
								<option value="span-target">span-target</option>
								<option value="span-source">span-source</option>
								<option value="freq" selected="selected">frequency</option>
								<option value="freq-target">freq-target</option>
								<option value="freq-source">freq-source</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Drop scores below:</span></td>
						<td>
							<select name="cutoff">
								<option value="0" selected="selected">no cutoff</option>
								<option value="3">3</option>
								<option value="4">4</option>
								<option value="5">5</option>
								<option value="6">6</option>
								<option value="7">7</option>
								<option value="8">8</option>
								<option value="9">9</option>
							</select>
						</td>
					</tr>
				</table>

				<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
			</form>
		</div>

		<?php include "last.php"; ?>

