		<?php include "first.php"; ?>
		
		<?php include "search_menu.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/table_full-target.pl'; ?>" method="post" ID="Form1">
				
				<h1>Version 3a</h1>
				
				<h2>Full-Target Display</h2>
				
				<p>
					This is an interface for a new experimental display.  Results are based on <a href="<?php echo $url_html . "/v3.php" ?>">V3a</a> and carry the same caveats.
				</p>
				
				<table class="input">
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
								<?php include $fs_html.'/textlist.la.r.php'; ?>
							</select>
			 			</td>
					</tr>
					<tr>
						<td>
							<input type="hidden" name="unit" value="line"/>
							<input type="hidden" name="feature" value="stem"/>
							<input type="hidden" name="stoplist" value="10"/>
						</td>
					</tr>
					<tr>
						<td colspan=2 align="center">
							<input type="submit" onclick="return ValidateForm()" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
						</td>
					</tr>
				</table>
			</form>
		</div>

		<script language="javascript">

                	var ddlsrc = document.getElementById('source');
                	var ddltrg = document.getElementById('target');

                	ddlsrc.options[0].selected = true;
                	ddltrg.options[ddltrg.options.length-1].selected = true;

        	</script>

		<?php include "last.php"; ?>

