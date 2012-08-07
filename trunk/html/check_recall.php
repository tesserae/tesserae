			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

			</div>
			
			<div id="main">

				<form action="<?php echo $url_cgi . '/read_table.pl' ?>" method="post" ID="Form1">

					<h1>Lucan-Vergil Recall Test</h1>

					<table class="input">
						<tr>
							<td><span class="h2">Source:</span></td>
							<td>Vergil - Aeneid</td>
						</tr>
						<tr>
							<td><span class="h2">Target:</span></td>
							<td>Lucan - Pharsalia - Book 1</td>
						</tr>
						<tr>
							<td><span class="h2">Unit:</span></td>
							<td>Phrase</td>
						</tr>
						<tr>
							<td><span class="h2">Feature:</span></td>
							<td>
								<select name="feature">
									<option value="word">exact form only</option>
									<option value="stem" selected="selected">lemma</option>
									<option value="syn">lemma + synonyms</option>
								</select>
							</td>
						</tr>
						<tr>
							<td><span class="h2">Number of stop words:</span></td>
							<td>
								<textarea name="stopwords" rows="1" maxlength="3" style="resize:none;">10</textarea>							
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
								<textarea name="dist" rows="1" maxlength="3" style="resize:none;">999</textarea>
							</td>
						</tr>
						<tr>
							<td><span class="h2">Distance metric:</span></td>
							<td>
								<select name="dibasis">
									<option value="span">span</option>
									<option value="span-target">span-target</option>
									<option value="span-source">span-source</option>
									<option value="freq">frequency</option>
									<option value="freq-target">freq-target</option>
									<option value="freq-source">freq-source</option>
								</select>
							</td>
						</tr>
						<tr>
							<td><span class="h2">Drop scores below:</span></td>
							<td>
								<textarea rows="1" name="cutoff" maxlength="5" style="resize:none;">0</textarea>
							</td>
						</tr>
					</table>
					
					<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
					
					<input type="hidden" name="source" value="vergil.aeneid"/>
					<input type="hidden" name="target" value="lucan.pharsalia.part.1"/>
					<input type="hidden" name="unit" value="phrase"/>
					<input type="hidden" name="frontend" value="recall"/>
					
				</form>
			</div>

			<div style="margin-left:100px;text-align:left;">
				<h2>Session Details</h2>
				
				<a name="fullinfo"></a>
				<p>
					<b>Session ID:</b>
					<!--session_id-->
					<br>
					<b>Unit:</b>
					<!--unit-->
					<br>
					<b>Feature:</b>
					<!--feature-->
					<br>
					<b>Stop words:</b>
					<!--stoplist-->
					<br>
					<b>Stoplist basis:</b>
					<!--stbasis-->
					<br>					
					<b>Max distance:</b>
					<!--dist-->
					<br>
					<b>Distance metric:</b>
					<!--dibasis-->
					<br>
					<b>Score cutoff:</b>
					<!--cutoff-->
					<br>
					<b>Comments:</b>
					<!--comment-->
					<br>
				</p>
			</div>
			
			<div>
				<b>Total results returned by Tesserae:</b>
				<!--all-results-->
				<br>
				<table class="output">
					<thead>
						<tr>
							<td>type</td>
							<td>tesserae returned</td>
							<td>benchmark has</td>
							<td>recall rate</td>
							<td>mean score</td>
						</tr>
					</thead>
					<tbody>
						<!--recall-stats-->
					</tbody>
				</table>
			</div>

			<table class="output" id="resultsTable">
				<thead>
					<tr>
						<th>BC</th>
						<th>Target Phrase</th>
						<th>Aeneid</th>
						<th>Source Phrase</th>
						<th>Parallel Type</th>
						<th>Tess Score</th>
						<th>Commentators</th>
					</tr>
				</thead>
				<tbody>
					<!--parallels-->
				</tbody>
			</table>
						
			<?php include "last.php"; ?>
