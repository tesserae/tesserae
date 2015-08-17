	<form action="<?php echo $url_cgi . '/read_table.pl' ?>" method="post" ID="Form1">

		<table class="input">
			<tr>
				<th>Source:</th>
				<td>
					<select name="source_auth" onchange="populate_work('<?php echo $lang['source']; ?>','source')">
					</select><br />
					<select name="source_work" onchange="populate_part('<?php echo $lang['source']; ?>','source')">
					</select><br />
					<select name="source">
					</select>
				</td>
			</tr>
			<tr>
				<th>Target:</th>
				<td>
					<select name="target_auth" onchange="populate_work('<?php echo $lang['target']; ?>','target')">
					</select><br />
					<select name="target_work" onchange="populate_part('<?php echo $lang['target']; ?>','target')">
					</select><br />
					<select name="target">
					</select>
				</td>
			</tr>
		</table>

		<div onclick="hideshow()" style="color:grey; text-align:center;">
			<p id="moremsg">show advanced</p>
		</div>
		<div id="advanced" style="display:none; background-color:white;">
			<table class="input">
				<tr>
					<th>Unit:</th>
					<td>
						<select name="unit">
							<option value="line">line</option>
							<option value="phrase">phrase</option>
						</select>
					</td>
				</tr>
				<tr>
					<th>Feature:</th>
					<td>
						<select name="feature">
							<?php
								foreach ($features as $k => $v) {
									$sel = '';
									if ($k == $selected_feature) {
										$sel = ' selected="selected"';
									}
									echo '<option value="' . $k .'"'. $sel .'>' . $v .'</option>';
								}
							?>
						</select>
					</td>
				</tr>
				<tr>
					<th>Number of stop words:</th>
					<td>
						<select name="stopwords">
							<option value="0">0</option>
							<option value="10" selected="selected">10</option>
							<option value="20">20</option>
							<option value="30">30</option>
							<option value="40">40</option>
							<option value="50">50</option>
							<option value="100">100</option>
							<option value="150">150</option>
							<option value="200">200</option>
						</select>							
					</td>
				</tr>
				<tr>
					<th>Stoplist basis:</th>
					<td>
						<select name="stbasis">
							<option value="corpus" selected="selected">corpus</option>
							<option value="target">target</option>
							<option value="source">source</option>
							<option value="both">target + source</option>
						</select>
					</td>
				</tr>
				<tr>
					<th>Score basis:</th>
					<td>
						<select name="score">
							<option value="word">word</option>
							<option value="stem" selected="selected">stem</option>							
						</select>
					</td>
				</tr>
				<tr>
					<th>Frequency basis:</th>
					<td>
						<select name="freq_basis">
							<option value="text">texts</option>
							<option value="corpus" selected="selected">corpus</option>
						</select>
					</td>
				</tr>				<tr>
					<th>Maximum distance:</th>
					<td>
						<select name="dist">
							<option value="999">no max</option>
							<option value="5">5 words</option>
							<option value="10" selected="selected">10 words</option>
							<option value="20">20 words</option>
							<option value="30">30 words</option>
							<option value="40">40 words</option>
							<option value="50">50 words</option>
						</select>							
					</td>
				</tr>
				<tr>
					<th>Distance metric:</th>
					<td>
						<select name="dibasis">
							<option value="span">span</option>
							<option value="span-target">span-target</option>
							<option value="span-source">span-source</option>
							<option value="freq" selected="selected">frequency</option>
							<option value="freq-target">freq-target</option>
							<option value="freq-source">freq-source</option>
						</select>
					</td>
				</tr>
				<tr>
					<th>Drop scores below:</td>
					<td>
						<select name="cutoff">
							<option value="0">no cutoff</option>
							<option value="3">3</option>
							<option value="4">4</option>
							<option value="5">5</option>
							<option value="6">6</option>
							<option value="7" selected="selected">7</option>
							<option value="8">8</option>
							<option value="9">9</option>
						</select>
					</td>
				</tr>
			</table>
		</div>
		<div style="text-align:center; padding:20px;">
			<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit" />
		</div>
		<div style="visibility:hidden">
				<select id="<?php echo $lang['target'].'_texts' ?>">
					<?php include $fs_html.'/textlist.'.$lang['target'].'.r.php'; ?>
				</select>
				<?php
					if ($lang['source'] != $lang['target']) {

						echo '<select id="'.$lang['source'].'_texts">';
						include $fs_html.'/textlist.'.$lang['source'].'.r.php';
						echo '</select>';
					}
					
					foreach ($hidden as $k => $v) {
					
						echo '<input type="hidden" name="' . $k . '" value="' . $v . '" />';
					}
				?>
		</div>
	</form>
	<script type="text/javascript">
		lang = {
			'target':'<?php echo $lang['target'] ?>',
			'source':'<?php echo $lang['source'] ?>'
		};
		selected = {
			'target':'<?php echo $selected['target'] ?>',
			'source':'<?php echo $selected['source'] ?>'
		};
		populate_author(lang['target'], 'target');
		populate_author(lang['source'], 'source');
		set_defaults(lang, selected);
	</script>
	