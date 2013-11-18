<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

<?php 
	$lang = 'la'; 
	$full_lang = 'Latin';
	$default_t = 'vergil.georgics.part.1';
	$default_s = 'catullus.carmina';
?>


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

		<h1>Welcome</h1>
		
		<p>
			The Tesserae project aims to provide a flexible and robust web interface for exploring intertextual parallels. 
			Select two poems below to see a list of lines sharing two or more words (regardless of inflectional changes).
			For advanced search options, select a language from the menu above.
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
		</table>

		<div style="text-align:center; padding:20px;">
			<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit" style=""/>
		</div>
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
		
	populate_author('source');
	populate_author('target');
	set_defaults();
</script>


<?php include "last.php"; ?>

