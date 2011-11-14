		<?php include "first.php"; ?>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
				
				<h1>Experimental Version</h1>
				
				<p>
					This page allows you to test out some new features currently in development.  
					Caution, results may be buggy and/or change without notice!
				</p>
				<p>
					If you're looking for stable results, please use <a href="<?php echo $url_html.'/v2.php'; ?>">Version 2</a>.
				</p>
				
				<table class = "input">
					<tr>
						<td align="center"><span class="h2">Source text</span></td>
						<td align="center"><span class="h2">Target text</span></td>
					</tr>
					<tr>
						<td align ="center">
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.la.php'; ?>
							</select>
			 			</td>
						<td align ="center">
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.la.php'; ?>
							</select>
			 			</td>
					</tr>
				</table>

				<h2>Units</h2>

				<p>
					Match
					<select name="unit" ID="unit">
						<option value="line" selected="selected">lines</option>
						<option value="phrase">phrases</option>
					</select>
				</p>
				
				<h2>Feature Set</h2>

				<p>
					Match on
					<select name="feature" ID="feature">
						<option value="word" selected="selected">words</option>
						<option value="stem">stems</option>
					</select>
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

