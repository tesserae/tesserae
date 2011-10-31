<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:variable name="sortkey" select="source"/>

   <xsl:include href="html-header-footer.xsl"/>
   
   <xsl:template match="results">

         <table class="output" id="resultsTable">
            <thead>
               <tr> 
                  <th></th>
                  <th class="phrase">source phrase</th>
                  <th class="phrase">target matches</th>
                  <th>matched on</th>
                  <th>score</th>
               </tr>
            </thead>
            <tbody>
               <xsl:apply-templates select="tessdata/phrase[@text='source']">
                  <xsl:sort select="substring-before(@line,'.')" data-type="number"/>
                  <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
               </xsl:apply-templates>
            </tbody>    
         </table>

   </xsl:template>
   
   
   <xsl:template match="phrase[@text='source']">
      <tr>
         <td>
            <xsl:value-of select="position()"/>
            <xsl:text>.</xsl:text>
         </td>
         <td>
            <table>
               <tr>
                  <td>
                     <a>
                        <xsl:attribute name="href">javascript:;</xsl:attribute>
                        <xsl:attribute name="onclick">
                           <xsl:text>window.open(link='</xsl:text>
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
            </table>
         </td>
         <td>
            <table>
               <xsl:for-each select="../phrase[@text='target']">
                  <tr>
                     <td>
                        <a>
                           <xsl:attribute name="href">javascript:;</xsl:attribute>
                           <xsl:attribute name="onclick">
                              <xsl:text>window.open(link='</xsl:text>
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
            </table>
         </td>
         <td>
            <xsl:value-of select="../@keypair"/>
         </td>
         <td>
            <xsl:value-of select="../@score"/>
         </td>
      </tr>
   </xsl:template>
   
</xsl:stylesheet>
