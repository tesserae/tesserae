<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">

<?php include "defs.php" ?>

<html lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="author" content="Neil Coffee, Jean-Pierre Koenig, Shakthi Poornima, Chris Forstall, Roelant Ossewaarde">
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin">
		<meta name="description" content="Intertext analyzer for Latin texts">
		<link href="<?php echo $url_css . "/style.css" ?>" rel="stylesheet" type="text/css"/>
		<link href="<?php echo $url_image . "/favicon.ico" ?>" rel="shortcut icon"/>
		
		<!--head_insert-->

		<title>Tesserae</title>

	</head>
	<body>

		<div id="container">

		<div id="header"> 
		
			<div style="position:fixed; top:0; right:0; z-index=100; color:red; font-size:1.1em">
				develop
			</div>
			<div id="header_image">
				<a href="<?php echo $url_html ?>">
					<img src="<?php echo $url_image . "/Tesserae.png" ?>" alt="Tesserae" width="300">
				</a>
			</div>		
			<div id="nav_main">
				<ul>
					<li><a href="<?php echo $url_html; ?>">Search</a></li>
					<li><a href="<?php echo $url_html . "/help.php"; ?>">Help</a></li>
					<li><a href="http://tesserae.caset.buffalo.edu/blog">Blog</a></li>

				</ul>
			</div>
