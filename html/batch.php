<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

		</div>
		<style type="text/css">
			table.input th {
				font-size: 1.2em;
				vertical-align: top; 
				width: 200px;
				overflow: hidden;
			}
			table.input td {
				overflow: hidden;
			}
		</style>

		
		<div id="main">
			
			<form action="<?php echo $url_cgi . '/batch.enqueue.pl' ?>" method="post" ID="Form1">

				<h1>Batch Processing</h1>
				
				<p>
					This experimental tool allows you to perform systematic series of
					Tesserae runs across a range of parameters.  Select single or
					multiple options using the controls below; Tesserae will be run once
					for each possible combination of the options selected.
				</p>
				
				<p>
					Depending on the number of searches necessary, results may take
					some time to generate.
				</p>

				<table class="input">
					<tr>
						<th>Source:</th>
						<td>
							<select name="source" ID="source" multiple="true">
								<?php include $fs_html.'/textlist.la.r.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<th>Target:</th>
						<td>
							<select name="target" ID="target" multiple="true">
								<?php include $fs_html.'/textlist.la.r.php'; ?>
							</select>
						</td>
					</tr>
				</table>
				<table class="input">
					<tr>
						<th>Unit:</th>
						<td>
							<input type="checkbox" name="unit" value="line" checked="checked">line</input>
							<input type="checkbox" name="unit" value="phrase">phrase</input>
						</td>
					</tr>
					<tr>
						<th>Feature:</th>
						<td>
							<input type="checkbox" name="feature" value="word">exact form only</input>
							<input type="checkbox" name="feature" value="stem" checked="checked">lemma</input>
							<input type="checkbox" name="feature" value="3gr">character 3-grams</input>
						</td>
					</tr>
					<tr>
						<th>Number of stop words:</th>
						<td>
							<input name="stop" size="80" maxlength="80" value="10"/>
						</td>
					</tr>
					<tr>
						<th>Stoplist basis:</th>
						<td>
							<input type="checkbox" name="stbasis" value="corpus">corpus</input>
							<input type="checkbox" name="stbasis" value="target">target</input>
							<input type="checkbox" name="stbasis" value="source">source</input>
							<input type="checkbox" name="stbasis" value="both" checked="checked">target + source</input>
						</td>
					</tr>
					<tr>
						<th>Score basis:</th>
						<td>
							<input type="checkbox" name="score" value="word">word</input>
							<input type="checkbox" name="score" value="stem" checked="checked">stem</input>
							<input type="checkbox" name="score" value="feature">feature</input>							
						</td>
					</tr>
					<tr>
						<th>Maximum distance:</th>
						<td>
							<input name="dist" size="80" maxlength="80" value="999"/>
						</td>
					</tr>
					<tr>
						<th>Distance metric:</th>
						<td>
							<input type="checkbox" name="dibasis" value="span">span</input>
							<input type="checkbox" name="dibasis" value="span-target">span-target</input>
							<input type="checkbox" name="dibasis" value="span-source">span-source</input>
							<input type="checkbox" name="dibasis" value="freq" checked="checked">frequency</input>
							<input type="checkbox" name="dibasis" value="freq-target">freq-target</input>
							<input type="checkbox" name="dibasis" value="freq-source">freq-source</input>
						</td>
					</tr>
					<tr>
						<th>Score cutoff:</th>
						<td>
							<input name="cutoff" size="80" maxlength="80" value="0"/>
						</td>
					</tr>
				</table>
				<div style="text-align:center; padding:20px;">
					<input type="submit" value="Prepare" ID="btnSubmit" NAME="btnSubmit" onclick="return validateForm()" method="post"/>
				</div>
			</form>
		</div>
		
		<script type="text/javascript">
					
			function validateForm() {
		
				var is_unselected = [];

				if (document.getElementsByName('source')[0].selectedIndex < 0) {
				
					is_unselected.push('source');
				}
				if (document.getElementsByName('target')[0].selectedIndex < 0) {
				
					is_unselected.push('target');
				}
				
				if (! anySelected('unit')) { 

					is_unselected.push('unit');
				}

				if (! anySelected('feature')) { 
					
					is_unselected.push('feature');
				}
								
				if (document.getElementsByName('stop')[0].value.search(/[0-9]/) < 0) {
				
					is_unselected.push('number of stop words');
				}
				
				if (! anySelected('stbasis')) { 
					
					is_unselected.push('stoplist basis');
				}

				if (document.getElementsByName('dist')[0].value.search(/[0-9]/) < 0) {
				
					is_unselected.push('maximum distance');
				}

				if (! anySelected('dibasis')) { 
					
					is_unselected.push('distance metric');
				}

				if (document.getElementsByName('cutoff')[0].value.search(/[0-9]/) < 0) {
				
					is_unselected.push('score cutoff');
				}
				
				var flag = true;
				
				for (var i = 0; i < is_unselected.length; i++) {
				
					is_unselected[i] = '\t-' + is_unselected[i];
					flag = false;
				}
				
				if (! flag) {
							
					alert('Select one or more values for the following:\n' + is_unselected.join('\n'));
				}
				
				return flag;
			}
			
			function anySelected(name) {
				
				var options = document.getElementsByName(name);
				
				var flag = false;
				
				for (i = 0; i < options.length; i++) {
									
					if (options[i].checked) { 

						flag = true;
					}
				}
				
				return flag;
			}
		</script>
		
		<?php include "last.php"; ?>

