<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<?php $url_html="http://tess.tamias" ?><!-- URL_HTML -->
<?php $url_css="http://tess.tamias/css" ?><!-- URL_CSS -->
<?php $url_cgi="http://tess.tamias/cgi-bin" ?><!-- URL_CGI -->
<?php $url_images="http://tess.tamias/images" ?><!-- URL_IMAGES -->
<?php $url_text="http://tess.tamias/texts" ?><!-- URL_TEXT -->
<?php $fs_html="/var/www/tesserae/html" ?><!-- FS_HTML -->


<html lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="author" content="Neil Coffee, Jean-Pierre Koenig, Shakthi Poornima, Chris Forstall, Roelant Ossewaarde">
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin">
		<meta name="description" content="Intertext analyzer for Latin texts">
		<link href="<?php echo $url_css.'/style.css' ?>" rel="stylesheet" type="text/css"/>
		<link href="<?php echo $url_images.'/favicon.ico' ?>" rel="shortcut icon"/>

		<title>Tesserae</title>

	</head>
	<body>

		<div id="container">

		<div id="header"> 
			<center>
				<h1><b>Tesserae</b></h1>
				<h2>Intertextual Phrase Matching</h2>
			</center>
		</div>

		<div id="links">
			<a href="<?php echo $url_html.'/index.php' ?>">Basic Search</a>
			| <a href="<?php echo $url_html.'/v2.php' ?>">Version 2</a>
			| <a href="<?php echo $url_html.'/help.php' ?>">Instructions</a>
			| <a href="<?php echo $url_html.'/about.php' ?>">About Tesserae</a>
			| <a href="<?php echo $url_html.'/research.php' ?>">Research</a>
		</div>
