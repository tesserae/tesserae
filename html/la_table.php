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
		'syn'  => 'synonym',
		'syn_lem'  => 'lemma + synonym',		
		'3gr'  => 'character 3-gram'
	);
	$selected_feature = 'stem';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

</div>
<div id="main">
	
	<h1>Latin Search</h1>
	
	<p>
		For explanations of advanced features, see the 
		<a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.
	</p>
	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

