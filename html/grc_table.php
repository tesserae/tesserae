<?php
	$lang = array(
		'target' => 'grc',
		'source' => 'grc'
	);
	$selected = array(
		'target' => 'apollonius.argonautica.part.1',
		'source' => 'homer.iliad'
	);
	$features = array(
		'word' => 'exact word',
		'stem' => 'lemma',
		'syn'  => 'lemma + synonyms',
		'3gr'  => 'character 3-gram'
	);
	$selected_feature = 'stem';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>
<?php include "nav_lang.php"; ?>
</div>
<div id="main">
	
	<h1>Greek Search</h1>
	
	<p>
		For explanations of advanced features, see the 
		<a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.
	</p>
	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

