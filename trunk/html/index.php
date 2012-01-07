			<?php include "first.php"; ?>

			<?php include "search_menu.php"; ?>

			</div>


			<div id="main">
				<h1>Basic Search</h1>

				<p>
					The Tesserae project aims to provide a flexible and robust web interface for exploring intertextual parallels. In a basic search, selected works of Latin authors can be compared. Phrases from the texts which match in at least two of six relatively unfrequent words are grouped together for comparison, with links to their original context.
				</p>

				<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
					<table class="input">

						<tr>
							<td align="center">
								<span class="h2">Source text</span>
							</td>	
							<td align="center">
								<span class="h2">Target text</span>
							</td>
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
						<tr>
							<td>
								<input type="hidden" name="unit" value="line"/>
								<input type="hidden" name="feature" value="stem"/>
								<input type="hidden" name="stoplist" value="20"/>
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
