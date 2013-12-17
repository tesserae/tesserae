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
		'trans1' => 'parallel texts method',
		'trans2' => 'dictionary method'
	);
	$selected_feature = 'trans1';
?>

<?php include "first.php"; ?>
<?php include "nav_search.php"; ?>

</div>
<div id="main">
	
	<h1>Latin-Greek Search</h1>
	
	<p>
		This search is experimental.  Results may not be consistent.
	</p>	

	<script src="<?php echo $url_html . '/tesserae.js' ?>"></script>

	<?php include "advanced.php"; ?>

</div>

<?php include "last.php"; ?>

