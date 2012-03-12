	<?php include "first.php"; ?>

	<?php include "nav_about.php"; ?>

			</div>

			<div id="main">
				<h1>Methods</h1>
				
				<h2>Dictionary</h2>

				<p>
					The dictionary headwords were determined using the 
					<a href="http://archimedes.mpiwg-berlin.mpg.de/arch/doc/xml-rpc.html">Archimedes Morphology Service</a>
					provided by the 
					<a href="http://archimedes2.mpiwg-berlin.mpg.de/archimedes_templates/project.htm">Archimedes Project</a>.
				</p>

				<h2>Texts</h2>
				<p>
					The Latin texts used were retrieved from the public domain works at 
					<a href="http://thelatinlibrary.com/">TheLatinLibrary.com</a>, and from the 
					<a href="http://www.perseus.tufts.edu">Perseus Digital Library</a>. 

					You can find specific information about the sources of the texts
					<a href="<?php echo $url_html.'/sources.php'; ?>">here</a>.  

					The texts' original HTML or XML markup was edited to remove extraneous tags and to clarify 
					line numbering.  Their Latin content was not altered, although editorial additions originally 
					appearing in angle-braces may have been accidentally removed or may appear without the braces.  
					You can view and download the text files used in our searches <a href="<?php echo $url_text; ?>">here</a>.
				</p>
			</div>

			<?php include "last.php"; ?>


