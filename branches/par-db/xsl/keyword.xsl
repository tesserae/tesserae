<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:variable name="sortkey" select="keyword"/>

   <xsl:include href="html-header-footer.xsl"/>
    
   <xsl:template match="results">
         
         <table class="output" id="resultsTable">
            <thead>
               <tr> 
                  <th></th>
                  <th>matched on</th>
                  <th class="phrase">target matches</th>
                  <th class="phrase">source matches</th>
                  <th>score</th>
               </tr>
            </thead>
            <xsl:apply-templates select="tessdata">
                <xsl:sort select="@keypair"/>
            </xsl:apply-templates>
         </table>

   </xsl:template>
    
    <xsl:template match="tessdata">
        <tr>
           <td>
            <xsl:value-of select="position()"/>
            <xsl:text>.</xsl:text>
           </td>
           <td>
              <xsl:value-of select="@keypair"/>
           </td>
           <td>
              <table>
                 <tr>
	            <xsl:apply-templates select="phrase[@text='target']">
                       <xsl:sort select="substring-before(@line,'.')" data-type="number"/>
                       <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
                    </xsl:apply-templates>
                 </tr>
              </table>
           </td>
           <td>
	      <table>
                 <tr>
                    <xsl:apply-templates select="phrase[@text='source']">
                       <xsl:sort select="substring-before(@line,'.')" data-type="number"/>
                       <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
                    </xsl:apply-templates>
                 </tr>
              </table>
           </td>
           <td>
              <xsl:value-of select="@score"/>
           </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="phrase">
       <tr>
          <td>
             <a>
                <xsl:attribute name="href">javascript:;</xsl:attribute>
		<xsl:attribute name="onclick">
                   <xsl:text>window.open(link='</xsl:text>
                   <xsl:value-of select="@link"/>
		   <xsl:text>', 'context', 'width=520,height=240')</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="@work"/><xsl:text> </xsl:text><xsl:value-of select="@line"/>
             </a>
          </td>
          <td>
             <xsl:copy-of select="."/>
          </td>
       </tr>
    </xsl:template>

</xsl:stylesheet>
