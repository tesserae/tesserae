</div>

<div id="main">
	
	<style type="text/css">
		table.input th {
			font-size: 1.2em;
			vertical-align: top; 
			width: 200px;
			overflow: hidden;
		}
		table.input td {
			overflow: hidden;
		}
	</style>
	
	<form action="<?php echo $url_cgi . '/read_table.pl' ?>" method="post" ID="Form1">

		<h1><?php echo $full_lang; ?> Search</h1>
		
		<p>
			This page allows you to change the default settings for the search. For explanations of the features, see the <a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.
		</p>

		<table class="input">
			<tr>
				<th>Source:</th>
				<td>
					<select name="source_auth" onchange="populate_work('source')">
					</select><br />
					<select name="source_work" onchange="populate_part('source')">
					</select><br />
					<select name="source">
					</select>
				</td>
			</tr>
			<tr>
				<th>Target:</th>
				<td>
					<select name="target_auth" onchange="populate_work('target')">
					</select><br />
					<select name="target_work" onchange="populate_part('target')">
					</select><br />
					<select name="target">
					</select>
				</td>
			</tr>
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
						<option value="word">exact form only</option>
						<option value="stem" selected="selected">lemma</option>
						<option value="syn">lemma + synonyms</option>
						<option value="3gr">character 3-grams</option>
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
		</table>
		
		<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
	</form>
</div>

<div>
		<select name="all_texts" style="visibility:hidden;">
			<?php include $fs_html.'/textlist.'.$lang.'.r.php'; ?>
		</select>
</div>

<script type="text/javascript">
	function populate_author(prefix) {
	
		var select_full = document.getElementsByName('all_texts')[0];
		var select_auth = document.getElementsByName(prefix.concat('_auth'))[0];
		
		var authors = {};
		
		for (var i=0; i<select_full.length; i++) { 
		
			var opt_this = select_full.options[i];
			
			var seg_value = opt_this.value.split('.');
			var seg_name = opt_this.text.split(' - ');
							
			authors[seg_value[0]] = seg_name[0];			
		}
		
		for (var i in authors) {
		
			var opt_new = new Option(authors[i], i);
			select_auth.add(opt_new);
		}
		
	populate_work(prefix);
	}
	
	function populate_work(prefix) {
	
		var select_full = document.getElementsByName('all_texts')[0];
		var select_auth = document.getElementsByName(prefix.concat('_auth'))[0];				
		var select_work = document.getElementsByName(prefix.concat('_work'))[0];
		
		var auth_master = select_auth.options[select_auth.selectedIndex].value
		var works = {};
		
		for (var i=0; i<select_full.length; i++) { 
		
			var opt_this = select_full.options[i];
			
			var seg_value = opt_this.value.split('.');
			var seg_name = opt_this.text.split(' - ');
			
			var auth_this = seg_value[0];
			var work_this = seg_value[1];
		
			if (auth_this == auth_master) {
				
				works[work_this] = seg_name[1];			
			}
		}
		
		for (var i=select_work.length-1; i>=0; i -= 1) {
			
			select_work.remove(i);
		}
		
		for (var i in works) {
		
			var opt_new = new Option(works[i], i);
			select_work.add(opt_new);
		}
				
		populate_part(prefix);
	}
	
	function populate_part(prefix) {
		
		var select_full = document.getElementsByName('all_texts')[0];
		var select_auth = document.getElementsByName(prefix.concat('_auth'))[0];
		var select_work = document.getElementsByName(prefix.concat('_work'))[0];
		var select_part = document.getElementsByName(prefix)[0];
		
		var auth_master = select_auth.options[select_auth.selectedIndex].value;
		var work_master = select_work.options[select_work.selectedIndex].value;
		var parts = {};
		
		for (var i=0; i<select_full.length; i++) { 
		
			var opt_this = select_full.options[i];
			
			var seg_value = opt_this.value.split('.');
			var seg_name = opt_this.text.split(' - ');
			
			var auth_this = seg_value[0];
			var work_this = seg_value[1];
							
			if (auth_this == auth_master && work_this == work_master) {
				
				if (seg_name.length > 2) {
					
					parts[seg_name[2]] = opt_this.value;
				}
				else {
				
					parts['Full Text'] = opt_this.value;
				}
			}
		}
		
		for (var i=select_part.length-1; i>=0; i -= 1) {
			
			select_part.remove(i);
		}
		
		for (var i in parts) {
		
			var opt_new = new Option(i, parts[i]);
			select_part.add(opt_new);
		}		
	}
	
	function set_defaults() {
		
		var selected = {};
		selected['target'] = '<?php echo $default_t ?>';
		selected['source'] = '<?php echo $default_s ?>';
		
		for (prefix in selected) {
		
			var select_auth = document.getElementsByName(prefix.concat('_auth'))[0];
			var select_work = document.getElementsByName(prefix.concat('_work'))[0];
			var select_part = document.getElementsByName(prefix)[0];
			
			var seg = selected[prefix].split('.');
			var auth = seg[0];
			var work = seg[1];
			
			for (var i=0; i < select_auth.options.length; i++) {
			
				if (select_auth.options[i].value == auth) {
				
					select_auth.selectedIndex = i;
				}
			}
			
			populate_work(prefix);

			for (var i=0; i < select_work.options.length; i++) {
			
				if (select_work.options[i].value == work) {
			
					select_work.selectedIndex = i;
				}
			}
			
			populate_part(prefix);

			for (var i=0; i < select_part.options.length; i++) {
			
				if (select_part.options[i].value == selected[prefix]) {
				
					select_part.selectedIndex = i;
				}
			}
		}
	}
		
	populate_author('source');
	populate_author('target');
	set_defaults();
</script>
