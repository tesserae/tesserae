<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

</div>

<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

<div id="main">
		
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
					<select name="source_auth" onchange="populate_work('la','source')">
					</select><br />
					<select name="source_work" onchange="populate_part('la','source')">
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

		<div style="text-align:center; padding:20px;">
			<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit" style=""/>
		</div>
	</form>
</div>

<div style="visibility:hidden">
		<select id="la_texts">
			<?php include $fs_html.'/textlist.la.r.php'; ?>
		</select>
</div>

<script type="text/javascript">
	lang = {
		'target':'la',
		'source':'la'
	};
	selected = {
		'target':'vergil.georgics.part.1',
		'source':'catullus.carmina'
	};

	populate_author(lang['target'], 'target');
	populate_author(lang['source'], 'source');
	set_defaults(lang, selected);	
</script>


<?php include "last.php"; ?>

