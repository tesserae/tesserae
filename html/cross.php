<?php include "first.php"; ?>		
<?php include "nav_search.php"; ?>

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

		<h1>Latin-Greek Search</h1>
		
		<p>
			This is experimental.  Results may not be consistent.
		</p>

		<table class="input">
			<tr>
				<th>Source:</th>
				<td>
					<select name="source_auth" onchange="populate_work('grc','source')">
					</select><br />
					<select name="source_work" onchange="populate_part('grc','source')">
					</select><br />
					<select name="source">
					</select>
				</td>
			</tr>
			<tr>
				<th>Target:</th>
				<td>
					<select name="target_auth" onchange="populate_work('la','target')">
					</select><br />
					<select name="target_work" onchange="populate_part('la','target')">
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
							<option value="trans1">Parallel Texts Method</option>
							<option value="trans2">Dictionary Method</option>
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
		</div>
		<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit"/>
	</form>
</div>

<div>
		<select name="grc_texts" style="visibility:hidden;">
			<?php include $fs_html.'/textlist.grc.r.php'; ?>
		</select>
		<select name="la_texts" style="visibility:hidden;">
			<?php include $fs_html.'/textlist.la.r.php'; ?>
		</select>
</div>

<script type="text/javascript">
	function populate_author(lang, prefix) {
	
		var select_full = document.getElementsByName(lang.concat('_texts'))[0];
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
		
		populate_work(lang,prefix);
	}
	
	function populate_work(lang, prefix) {
	
		var select_full = document.getElementsByName(lang.concat('_texts'))[0];
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
				
		populate_part(lang,prefix);
	}
	
	function populate_part(lang, prefix) {
		
		var select_full = document.getElementsByName(lang.concat('_texts'))[0];
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
		var lang = {}
		selected['target'] = 'vergil.aeneid.part.1';
		selected['source'] = 'homer.iliad';
		lang['target'] = 'la';
		lang['source'] = 'grc';
		
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
			
			populate_work(lang[prefix],prefix);

			for (var i=0; i < select_work.options.length; i++) {
			
				if (select_work.options[i].value == work) {
			
					select_work.selectedIndex = i;
				}
			}
			
			populate_part(lang[prefix],prefix);

			for (var i=0; i < select_part.options.length; i++) {
			
				if (select_part.options[i].value == selected[prefix]) {
				
					select_part.selectedIndex = i;
				}
			}
		}
	}
	
	function hideshow() {

		var adv = document.getElementById('advanced');
		var msg = document.getElementById('moremsg');
		
		if (adv.style.display !== 'none') {
			adv.style.display = 'none';
			msg.innerHTML = 'show advanced'
		}
		else {
			adv.style.display = 'block';
			msg.innerHTML = 'hide advanced'
		}
	}
		
	populate_author('grc', 'source');
	populate_author('la', 'target');
	set_defaults();
</script>


	<?php include "last.php"; ?>

