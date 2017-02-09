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
		'syn'  => 'semantic',
		'syn_lem'  => 'lemma + semantic',		
		'3gr'  => 'sound'
	);
	$selected_feature = 'stem';
	$page = 'search';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

</div>


<?php include "nav_lang.php"; ?>	
<div id="main">

	<h1>Latin Search</h1>
	
	<p>
		The Tesserae project aims to provide a flexible and robust web interface for exploring intertextual parallels. 
		Select two poems below to see a list of lines sharing two or more words (regardless of inflectional changes).
	</p>
	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

