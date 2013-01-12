<?php include "first.php"; ?>
<?php include "nav_research.php"; ?>

			</div>

			<div id="main">
				<a name="top"></a>

				<h1>Research at Tesserae</h1>

				<h2>Case Study: Lucan <em>Pharsalia</em> Book 1 and Vergil <em>Aeneid</em></h2>
				<p>
					Our first large-scale application of Tesserae to a literary-critical 
					project has been a study of Lucan's allusions to the <em>Aeneid</em> in 
					<em>Pharsalia</em> book 1.
				</p> 

				<h3>Tesserae Data</h3>
				<p>
					We combined results returned by both the Basic Search and (an earlier 
					implementation of) the Version 2 Search, both run on Lucan - Pharsalia Book 1 
					as the Target text and Vergil - Aeneid as the Source text.
				</p>
				
				<h3>Commentators' Data</h3>
				<p>
					For comparison, we collated all allusions noted by four modern commentaries
					on Lucan:
				</p>
				<ul>
					<li>Heitland and Haskins (1887) <em>M. Annaei Lucani Pharsalia</em>. London: G. Bell.</li>
					<li>Thompson and Bruère (1968) Lucan’s Use of Vergilian Reminiscence. <em>Classical Philology</em> 63: 1–21.</li>
					<li>Viansino (1995) <em>Marco Annaeo Lucano: La Guerra Civile (Farsaglia) libri I-V</em>. Milan: Arnoldo Mondadori.</li>
					<li>Roche (2009) <em>Lucan: De bello civili. Book 1</em>. Oxford: Oxford University Press.</li>
				</ul>

				<h3>Evaluation and Ranking</h3>

				<p>
					The combined list of results reported by both versions of Tesserae and the four
					commentaries comprised 3100 parallels.  Over the course of a semester-long graduate
					seminar in the University at Buffalo's Classics Department, each of these was examined
					individually and given a rank according to its literary significance.  Because this
					was a subjective and collaborative procedure, we also developed the following general
					schema for ranking parallels.
				</p>
				<table class="data">
					<caption>Ranking Schema for Parallels</caption>
					<tr>
						<th>Type</th>
						<th>Characteristics</th>
					</tr>
					<tr>
						<th>5</th>
						<td>High formal similarity in analogous context.</td>
					</tr>
					<tr>
						<th>4</th>
						<td>
							Moderate formal similarity in analogous context; or <br />
							High formal similarity in moderately analogous context.
						</td>
					</tr>
					<tr>
						<th>3</th>
						<td>
							High / moderate formal similarity with very common phrase or words; or <br />
							High / moderate formal similarity with no analogous context; or <br />
							Moderate formal similarity with moderate / highly analogous context.
						</td>
					</tr>
					<tr>
						<th>2</th>
						<td>
							Very common words in very common phrase; or <br />
							Words too distant to form a phrase.
						</td>
					</tr>
					<tr>
						<th>1</th><td>Error in discovery algorithm, words should not have matched.</td>
					</tr>
				</table>

				<h3>Results</h3>

				<p>
					Of the most significant allusions (Type 4-5), the combined efforts of the commentators
					discovered 172, while Tesserae discovered 93.  This indicates that even at the present
					prototype stage, the tool is returning significant numbers of allusions.
				</p>
				<p>
					A major difference between Tesserae and the commentators was the number of low-ranked
					parallels returned.  While these may prove useful to new kinds of philological research
					in the future, the traditional student of allusion would prefer to be able to quickly
					filter out instances of generic language re-use.  We are currently working on developing
					an automatic ranking system that can take over some of the work done by hand in the
					present study.
				</p>
				<p>
					Another important difference between Tesserae and the commentators is which allusions
					were returned.  Although Tesserae reported comparable numbers of parallels, only half
					of the results were parallels noted in any of the commentaries.  That means that this
					experiment has already increased the number of identified <em>Aeneid</em> allusions in
					<em>Pharsalia</em> Book 1 by 25%!
				</p>
				<table class="data">
					<caption>Number of parallels returned</caption>

					<tr><th>Type</th><th>Tesserae</th><th>All Commentaries</th><td>Roche</td><td>Viansino</td><td>T &amp; B</td><td>H &amp; H</td><th>Total</th></tr>
					<tr><td>1</td><td>486</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>486</td></tr>
					<tr><td>2</td><td>2241</td><td>55</td><td>50</td><td>8</td><td>1</td><td>1</td><td>2289</td></tr>
					<tr><td>3</td><td>280</td><td>192</td><td>168</td><td>33</td><td>13</td><td>6</td><td>425</td></tr>
					<tr><td>4</td><td>57</td><td>79</td><td>66</td><td>18</td><td>12</td><td>3</td><td>115</td></tr>
					<tr><td>5</td><td>36</td><td>93</td><td>85</td><td>30</td><td>14</td><td>4</td><td>103</td></tr>
					<tr><th>Total</th><th>3100</th><th>419</th><th>369</th><th>89</th><th>40</th><th>14</th><th>3418</th></tr>
					<tr>
							<td colspan="8" class="footnote">
							Note: where multiple sources found the same parallel, it is counted only once in summary columns;
							totals may thus be less than the sum of individual values.
							</td>
					</tr>
				</table>

				<div class="figure">
					<img src="<?php echo $url_image . '/venn_dia.png' ?>" alt="overlap between tesserae and commentaries" width="300">
					<div class="figure_caption">
						Overlap between Tesserae and commentaries: <br /> Type 4-5 Parallels
					</div>
				</div>

			</div>

			<?php include "last.php"; ?>


