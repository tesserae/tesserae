<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

		</div>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/session.pl'; ?>" method="post" ID="Form1">
				
				<h1>Version 1</h1>
				
				<h2>Basic V1 Search</h2>
				
				<p>
					This page provides access to our first algorithm, for those who need continuity with earlier work.  Please note that while the algorithm itself has not been changed, several other aspects of our database have been upgraded, and so these results may differ slightly from earlier implementations.  For further information, please see the Help page or contact us.
				</p>
				
				<table class="input">
					<tr>
						<td align="center"><span class="h2">Source text</span></td>
						<td align="center"><span class="h2">Target text</span></td>
					</tr>
					<tr>
						<td align ="center">
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.v1.php'; ?>
							</select>
			 			</td>
						<td align ="center">
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.v1.php'; ?>
							</select>
			 			</td>
					</tr>
					<tr>
						<td>
							<input type="hidden" name="unit" value="word"/>
							<input type="hidden" name="cutoff" value="10"/>
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

