			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

			</div>
			
			<div id="main">
					<!--info-->
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

			<div id="results_sort">
				<!--sort-->
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
