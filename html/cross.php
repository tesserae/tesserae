<?php
	$lang = array(
		'target' => 'la',
		'source' => 'grc'
	);
	$selected = array(
		'target' => 'vergil.aeneid.part.1',
		'source' => 'homer.iliad'
	);
	$features = array(
		'g_l' => 'Greek-Latin dictionary'
	);
	$selected_feature = 'g_l';
	$page = 'search';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

</div>
<?php include "nav_lang.php"; ?>
<div id="main">
	
	<h1>Greek-To-Latin Search</h1>
	
	<p>
		To learn more about the Latin-Greek search method, visit the 
		<a href="http://tesserae.caset.buffalo.edu/blog/latin-greek-search-competing-methods/" target="_blank">blog</a>.<br>
				For explanations of advanced features, see the 
		<a href="<?php echo $url_html . '/help_advanced.php' ?>">Instructions</a> page.

	</p>	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

