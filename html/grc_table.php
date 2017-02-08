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
		'syn' => 'semantic',
		'syn_lem' => 'lemma + semantic',
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
	
	<h1>Greek Search</h1>
	<p>
		The Tesserae project aims to provide a flexible and robust web interface for exploring intertextual parallels. 
		Select two poems below to see a list of lines sharing two or more words (regardless of inflectional changes).
	</p>
		<p>
<font color='red'>Semantic search</font> that identifies parallels with related meaning is now available under show <i>advanced/ feature / lemma + semantic.</i>  For an explanation see <a href="http://tesserae.caset.buffalo.edu/blog/version-3-1-capturing-more-parallels-and-sorting-them-better/" target="_blank">here</a>.
	</p>
	<p>
		For an overview of all advanced features, see the 
		<a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.
	</p>
	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

