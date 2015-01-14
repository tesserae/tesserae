<?php
	$lang = array(
		'target' => 'en',
		'source' => 'en'
	);
	$selected = array(
		'target' => 'wordsworth.prelude.part.1',
		'source' => 'cowper.task'
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
<?php include "nav_lang.php"; ?>

<div id="main">
	
	<h1>English Search</h1>
	
	<p>
		NB. English search is untested; some texts have not yet been proofread thoroughly.
		<a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.
	</p>
	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

