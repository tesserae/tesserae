<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

			</div>

			<div id="main">
				<h1>Version 2 Search</h1>

				<p>
					In this search, a parallel is returned if two grammatical sentences share two or more common words.  Words are "common" if the inflected forms in the text can be traced to the same dictionary headword.  An inflected form which is ambiguous will match to any of the possible lemmata.
				</p>
				
				<p>
					Version 2 searches on large texts may be quite slow (up to 10 minutes).  This algorithm has largely been superceded by <a href="<?php echo $url_html . "/la_table.php" ?>">Version 3</a>, which produces slightly different&mdash;but faster&mdash;results.
				</p>
				

				<form action="<?php echo $url_cgi.'/compare_texts.pl'; ?>" method="post" ID="Form1">
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
									<?php include $url_html."/textlist.v2.php"; ?>
								</select>
 							</td>
							<td align ="center">
								<select name="target" ID="target">
									<?php include $url_html."/textlist.v2.php"; ?>
								</select>
 							</td>
						</tr>
						<tr>
							<td>
								
								<input type="hidden" name="unit" value="words"/>
								<input type="hidden" name="cutoff" value="30"/>
								<input type="hidden" ID="ignore_low" name="ignore_low" value="yes"/>
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
