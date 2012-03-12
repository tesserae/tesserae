		<?php include "first.php"; ?>
		
		<?php include "nav_search.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
				
				<h1>Greek Search</h1>
				
				<p>
					This is the prototype for our forthcoming Greek search.  Texts will be very limited, likely until Fall 2012.
				</p>
				<p>
						These results have not been tested.  If you notice anything interesting (or broken), please let us know.
				</p>
				
				<table class = "input">
					<tr>
						<td align="center"><span class="h2">Source text</span></td>
						<td align="center"><span class="h2">Target text</span></td>
					</tr>
					<tr>
						<td align ="center">
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.grc.l.php'; ?>
							</select>
			 			</td>
						<td align ="center">
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.grc.r.php'; ?>
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
						<option value="word">words</option>
						<option value="stem" selected="selected">stems</option>
					</select>
				</p>

				<input type="hidden" name="stoplist" value="50"/>

				<center>
					<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
				</center>
			</form>
		</div>

		<script language="javascript">

                	var ddlsrc = document.getElementById('source');
                	var ddltrg = document.getElementById('target');

                	ddlsrc.options[0].selected = true;
                	ddltrg.options[ddltrg.options.length-1].selected = true;

        	</script>

		<?php include "last.php"; ?>

