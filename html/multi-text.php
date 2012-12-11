		<?php include "first.php"; ?>
		
		<?php include "nav_search.php"; ?>

		</div>                                   
	  
		<div id="main">
			
			<form action="<?php echo $url_cgi.'/read_table.pl'; ?>" method="post" ID="Form1">
								
				<h1>Corpus-wide Search</h1>
				
				<p>
					This experimental search cross-checks your results against all other
					texts in the corpus. This will allow you to see whether a particular
					parallel is unique to your two selected works, or whether there is 
					a broader precedent for the repeated expression.
				</p>
				
				<table class="input">
					<tr>
						<td><span class="h2">Source:</span></td>
						<td>
							<select name="source" ID="source">
								<?php include $fs_html.'/textlist.la.l.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Target:</span></td>
						<td>
							<select name="target" ID="target">
								<?php include $fs_html.'/textlist.la.r.php'; ?>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Unit:</span></td>
						<td>
							<select name="unit">
								<option value="line">line</option>
								<option value="phrase">phrase</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Feature:</span></td>
						<td>
							<select name="feature">
								<option value="word">exact form only</option>
								<option value="stem" selected="selected">lemma</option>
								<option value="syn">lemma + synonyms</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Number of stop words:</span></td>
						<td>
							<select name="stopwords">
								<option value="0">0</option>
								<option value="10" selected="selected">10</option>
								<option value="20">20</option>
								<option value="30">30</option>
								<option value="40">40</option>
								<option value="50">50</option>
								<option value="100">100</option>
								<option value="150">150</option>
								<option value="200">200</option>
							</select>							
						</td>
					</tr>
					<tr>
						<td><span class="h2">Stoplist basis:</span></td>
						<td>
							<select name="stbasis">
								<option value="corpus">corpus</option>
								<option value="target">target</option>
								<option value="source">source</option>
								<option value="both">target + source</option>
							</select>
						</td>
					</tr>
					<tr>
						<td><span class="h2">Maximum distance:</span></td>
						<td>
							<select name="dist">
								<option value="999" selected="selected">no max</option>
								<option value="5">5 words</option>
								<option value="10">10 words</option>
								<option value="20">20 words</option>
								<option value="30">30 words</option>
								<option value="40">40 words</option>
								<option value="50">50 words</option>
							</select>							
						</td>
					</tr>
					<tr>
						<td><span class="h2">Distance metric:</span></td>
						<td>
							<select name="dibasis">
								<option value="span">span</option>
								<option value="span-target">span-target</option>
								<option value="span-source">span-source</option>
								<option value="freq">frequency</option>
								<option value="freq-target">freq-target</option>
								<option value="freq-source">freq-source</option>
							</select>
						</td>
					</tr>
					<tr>
     						<td><span class="h2">Drop scores below:</span></td>
                                                <td>
                                                        <select name="cutoff">
                                                                <option value="0" selected="selected">no cutoff</option>
                                                                <option value="3">3</option>
                                                                <option value="4">4</option>
                                                                <option value="5">5</option>
                                                                <option value="6">6</option>
                                                                <option value="7">7</option>
                                                                <option value="8">8</option>
                                                                <option value="9">9</option>
                                                        </select>
                                                </td>
					</tr>
					<tr>
						<td><span class="h2">Filter matches with other texts:</span></td>
                                                <td>
                                                        <select name="mcutoff">
                                                                <option value="0" selected="selected">no filter</option>
                                                                <option value="2">more results</option>
                                                                <option value="3">moderate</option>
                                                                <option value="6">fewest results</option>
                                                        </select>
                                                </td>

					</tr>
					<tr>
						<td><span class="h2">Texts to search:</span></td>
						<td><input type="checkbox" id="select_all" onclick="return SelectAll()" value=1>Select All</input></td>
					</tr>
				</table>                       
				
				<h2></h2>
					<?php include $fs_html . '/textlist.la.multi.php' ?>
				</tr>

				<p>
					<input type="hidden" name="frontend" value="multi" />
					<input type="submit" value="Compare Texts" ID="btnSubmit" NAME="btnSubmit" />
				</p>
		</form>
		</div>
                 
		<script language="javascript">
		
			function SelectAll() {                             
				var master = document.getElementById('select_all');
  			   var chkbox = document.getElementsByName('include');
				                                            
				for (var i = 0; i < chkbox.length; i++) {
				 
				  chkbox[i].checked = master.checked;
				}
			}
		</script>

		<?php include "last.php"; ?>

