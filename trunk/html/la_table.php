		<?php include "first.php"; ?>
		
		<?php include "search_menu.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
					
				<h2>Advanced Features</h2>
				
				<p>
					This page allows you to change the default settings for the search.  For explanations of the features, see the <a href="<?php echo $url_html . '/help.php' ?>"> Instructions</a> page.
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
						<td align ="center">
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.la.l.php'; ?>
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
						<option value="window">six-word window</option>
					</select>
				</p>
				
				<h2>Feature Set</h2>

				<p>
					Match on
					<select name="feature" ID="feature">
						<option value="stem" selected="selected">lemma</option>
						<option value="word">exact form only</option>
					</select>
				</p>

				<h2>Exclude Features</h2>

				<p>
					Omit matches on
					<select name="stoplist" ID="stoplist">
						<option value="0">none</option>
						<option value="10">top 10</option>
						<option value="20" selected="selected">top 20</option>
						<option value="50">top 50</option>
						<option value="100">top 100</option>
					</select>
					of the most frequent Latin words.
				</p>
				
				<p>
					<center>
						<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
					</center>
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

