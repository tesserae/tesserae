			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

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
							<td>recall</td>
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
