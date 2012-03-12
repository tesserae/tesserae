		<?php include "first.php"; ?>

		<?php include "nav_search.php"; ?>		

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi . '/session.pl' ?>" method="post" ID="Form1">
				
				<h1>Version 1</h1>
				
				<h2>Advanced Features</h2>
				
				<p>
					This page allows you to change the default settings for the 
					<a href="<?php echo $url_html.'/index.php' ?>">Basic Search</a>.
					
					To explore other search algorithms, please try 
					<a href="<?php echo $url_html.'/v2.php' ?>">Version 2</a> or the experimental
					<a href="<?php echo $url_html.'/la_table' ?>">Big Table</a>.
				</p>
				
				<table class = "input">
					<tr>
						<td align="center"><span class="h2">Source text</span></td>
						<td align="center"><span class="h2">Target text</span></td>
					</tr>
					<tr>
						<td align ="center">
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.la.l.php'; ?>
							</select>
						</td>
						<td align="center">
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.la.l.php'; ?>
							</select>
			 			</td>
					</tr>
				</table>

				<h2>Feature Set</h2>

				<p>
					Match on
					<select name="unit" ID="unit">
						<option value="word" selected="selected">words</option>
						<option value="stem">stems (temporarily unavailable)</option>
					</select>
				</p>

				<h2>Exclude Features</h2>

				<p>
					Omit matches on
					<select name="cutoff" ID="cutoff">
						<option value="0">none</option>
						<option value="10">top 10</option>
						<option value="50">top 50</option>
						<option value="100">top 100</option>
					</select>
					of the most frequent Latin words.
				</p>

				<p>
					Omit matches on the following additional words:
				</p>

				<p>
					<textarea name="stopwords" rows="10" cols="30"></textarea>
				</p>

				<p>
					<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
				</p>
			</form>
		</div>
		<script language="javascript">

                	var ddlsrc = document.getElementById('source');
                	var ddltrg = document.getElementById('target');

                	ddlsrc.options[0].selected = true;
                	ddltrg.options[ddltrg.options.length-1].selected = true;

        	</script>

		<?php include "last.php"; ?>

