<?php
	$lang = array(
		'target' => 'la',
		'source' => 'la'
	);
	$selected = array(
		'target' => 'vergil.georgics.part.1',
		'source' => 'catullus.carmina'
	);
	$features = array(
		'word' => 'exact word',
		'stem' => 'lemma',
		'3gr'  => 'character 3-gram'
	);
	$selected_feature = 'stem';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

		</div>                                   
	  
		<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>
		
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
								
				<h1>Corpus-wide Search</h1>
				
				<p>
					This experimental search cross-checks your results against all other
					texts in the corpus. This will allow you to see whether a particular
					parallel is unique to your two selected works, or whether there is 
					a broader precedent for the repeated expression.
				</p>
				
				<table class="input">
					<tr>
						<th>Source:</th>
						<td>
							<select name="source_auth" onchange="populate_work('<?php echo $lang['source'] ?>', 'source')">
							</select><br />
							<select name="source_work" onchange="populate_part('<?php echo $lang['source'] ?>', 'source')">
							</select><br />
							<select name="source">
							</select>
						</td>
					</tr>
					<tr>
						<th>Target:</th>
						<td>
							<select name="target_auth" onchange="populate_work('<?php echo $lang['target'] ?>', 'target')">
							</select><br />
							<select name="target_work" onchange="populate_part('<?php echo $lang['target'] ?>', 'target')">
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
									<option value="corpus">corpus</option>
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
									<option value="stem">stem</option>
									<option value="feature">feature</option>								
								</select>
							</td>
						</tr>
						<tr>
							<th>Maximum distance:</th>
							<td>
								<select name="dist">
									<option value="999" selected="selected">no max</option>
									<option value="5">5 words</option>
									<option value="10">10 words</option>
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
									<option value="0" selected="selected">no cutoff</option>
									<option value="3">3</option>
									<option value="4">4</option>
									<option value="5">5</option>
									<option value="6">6</option>
									<option value="7">7</option>
									<option value="8">8</option>
									<option value="9">9</option>
								</select>
							</td>
						</tr>
						<tr>
							<th>Filter matches with other texts:</th>
							<td>
								<select name="mcutoff">
									<option value="0" selected="selected">no filter</option>
									<option value="2">more results</option>
									<option value="3">moderate</option>
									<option value="6">fewest results</option>
								</select>
							</td>
						</tr>
					</table>
				</div>
				<table class="input">
					<tr>
						<th>Texts to cross-reference:</th>
						<td>
							<input type="checkbox" id="select_all"   onclick="return SelectAll()">Select All</input>
							<input type="checkbox" id="select_prose" onclick="return SelectCat(this)" class="prose">Prose Only</input>
							<input type="checkbox" id="select_verse" onclick="return SelectCat(this)" class="verse">Verse Only</input>
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<select name="include" ID="include" multiple="true">
								<?php include $fs_html.'/textlist.la.l.php'; ?>
							</select>
						</td>
					</tr>
				</table>
				<div style="text-align:center; padding:20px;">
					<input type="hidden" name="frontend" value="multi" />
					<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit" style=""/>
				</div>
			</form>
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
				?>
		</div>

		<script language="javascript">
		
			function SelectAll() {                             
				var dominus = document.getElementById('select_all');
  			   var servus  = document.getElementById('include');
				                                            
				for (var i = 0; i < servus.length; i++) {
				 
				  servus[i].selected = dominus.checked;
				}
				
				var prose = document.getElementById('select_prose');
				var verse = document.getElementById('select_verse');
				
				prose.checked = false;
				verse.checked = false;
			}
			function SelectCat(dominus) {                             
  			   var servus = document.getElementById('include');
				                                            
				for (var i = 0; i < servus.length; i++) {
					
					if (servus[i].getAttribute("class") == dominus.getAttribute("class")) {
				  		servus[i].selected = dominus.checked;
					}
				}
				
				var all = document.getElementById('select_all'); 
				all.checked = false;
			}

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

		<?php include "last.php"; ?>

