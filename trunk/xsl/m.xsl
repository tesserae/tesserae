<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" doctype-public="-//WAPFORUM//DTD XHTML Mobile 1.0//EN" encoding="iso-8859-1" indent="yes"/>
   <xsl:template match="/">
      <html>
         <head>
            <title>Tesserae</title>
            <link rel="stylesheet" type="text/css" href="http://www.acsu.buffalo.edu/~forstall/m/mobi.css" />
         </head>

         <body>
            <div id="container">
				<div id="top">
					<center>
						<h1><b>Tesserae</b></h1>
						<h2>Intertextual Phrase Matching</h2>
					</center>
	  			</div>

	  			<div id="links">
					<a href="" class="selected">Basic Search</a>
					| 
		    		<a href="/index.php">Full Site</a>
	  			</div>

            <xsl:apply-templates select="results"/>

				<div id="footer">

      				<div id="footer_content">
            			<p>
    						This project is funded by the 
							<a href="http://digitalhumanities.buffalo.edu/"><b>Digital Humanities Initiative at Buffalo</b></a>. Inquiries or comments about this website should be directed to 
<a href="mailto:ncoffee@buffalo.edu"><b>Neil Coffee</b></a>.
							<div style="text-align:center;">
           						Department of Classics | 338 MFAC | Buffalo, NY 14261
								<br />
           						tel: (716) 645-2154 | fax: (716) 645-2225
							</div>
						</p>
      				</div>
   				</div>
			</div>
         </body>
      </html>
   </xsl:template>
    
   <xsl:template match="results">
		<div class="results">

		   <p>
		      <b>Source Text: </b>
		      <a>
		         <xsl:attribute name="href">
		            <xsl:value-of select="concat('http://tesserae.caset.buffalo.edu/line_numbered_texts/', @source)"/>
		         </xsl:attribute>
		         <xsl:value-of select="@source"/>
		      </a>
         
		      <br/>
         
		      <b>Target Text: </b>
		      <a>
		         <xsl:attribute name="href">
		            <xsl:value-of select="concat('http://tesserae.caset.buffalo.edu/line_numbered_texts/', @target)"/>
		         </xsl:attribute>
		         <xsl:value-of select="@target"/>             
		      </a>
		   </p>
			
	 		<table class="output" id="ResultsTable">
		   	<xsl:apply-templates select="tessdata/phrase[@text='target']">
			   		<xsl:sort select="substring-before(@line,'.')" data-type="number"/>
			        <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
	      	</xsl:apply-templates>
			</table>
		</div>
	</xsl:template>
    
    
	<xsl:template match="phrase[@text='target']">
				<tr class="newgroup">
					<td>
            		<xsl:value-of select="position()"/>
            		<xsl:text>.</xsl:text>
          		</td>
          		<td>
             		<a>
                		<xsl:attribute name="href">javascript:;</xsl:attribute>
		          		<xsl:attribute name="onclick">
                   		<xsl:text>window.open(link='http://tesserae.caset.buffalo.edu</xsl:text>
                   		<xsl:value-of select="@link"/>
		             		<xsl:text>', 'context', 'width=520,height=240')</xsl:text>
                		</xsl:attribute>
                		<xsl:value-of select="@work"/>
                		<xsl:text> </xsl:text>
                		<xsl:value-of select="@line"/>
             		</a>
          		</td>
          		<td>
             		<xsl:copy-of select="."/>
          		</td>
				</tr>
	         <xsl:for-each select="../phrase[@text='source']">
	            <tr>
						<td></td>
	               <td>
	                  <a>
	                     <xsl:attribute name="href">javascript:;</xsl:attribute>
                        <xsl:attribute name="onclick">
                           <xsl:text>window.open(link='http://tesserae.caset.buffalo.edu</xsl:text>
                           <xsl:value-of select="@link"/>
                           <xsl:text>', 'context', 'width=520,height=240')</xsl:text>   
                        </xsl:attribute>
                        <xsl:value-of select="@work"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="@line"/>
							</a>
						</td>
                  <td><xsl:copy-of select="."/></td>
					</tr>
				</xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
