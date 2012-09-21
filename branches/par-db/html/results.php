			<?php include "first.php"; ?>

			<?php include "nav_search.php"; ?>

			</div>

			<div id="results_sort">
				<!--sorter-->
			</div>
			
			<div id="pager">
				<!--pager-->
			</div>
			
			<!-- Table of results -->
			
			<table class="output" id="resultsTable">
				<thead>
					<tr>
						<th></th>
						<th class="phrase">target phrase</th>
						<th class="phrase">source phrase</th>
						<th>matched on</th>
						<th>score</th>
					</tr>
				</thead>
				<tbody>
		
					<!--results-->
		
				</tbody>
			</table>
		
			<div style="margin:1em;text-align:left;">
				<a href="#top">Back to top</a>
			</div>
		
			<div style="margin-left:100px;text-align:left;">
				<h2>Session Details</h2>
				<a name="fullinfo"></a>
				<p>
					<b>Session ID:</b>
					<!--session_id-->
				</p>
				<p>
					<b>Source Text:</b>
					<!--source-->
					<br>
					<b>Target Text:</b>
					<!--target-->
				</p>
				<p>
					<b>Comments:</b>
					<!--comments-->
				</p>
				<p>
					<b>Stop words:</b>
					<!--stoplist-->
				</p>
			</div>
		
			<?php include "last.php"; ?>
