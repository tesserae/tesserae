<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:variable name="url_html" select="'http://tess.tamias/html'"/><!-- URL_HTML -->
<xsl:variable name="url_text" select="'http://tess.tamias/texts'"/><!-- URL_TEXT -->

	<xsl:output method="text"/>

	<xsl:template match="/">

   	<xsl:text>Tesserae</xsl:text>

<xsl:text>

Source Text: </xsl:text>

	   <xsl:value-of select="concat($url_text, results/@source)"/>

<xsl:text>
Target Text: </xsl:text>

	   <xsl:value-of select="concat($url_text, results/@target)"/> 

<xsl:text>

For help or further information, visit </xsl:text>
<xsl:value-of select="$url_html"/>
<xsl:text>
</xsl:text>

		<xsl:apply-templates select="results"/>
	</xsl:template>
   

   <xsl:template match="results">

<xsl:text>
Session: </xsl:text>

      <xsl:value-of select="@sessionID"/>

<xsl:text>
Comments: </xsl:text>

      <xsl:value-of select="comments"/>

<xsl:text>
</xsl:text>

      <xsl:apply-templates select="tessdata/phrase[@text='source']">
               <xsl:sort select="substring-before(@line,'.')" data-type="number"/>
               <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
      </xsl:apply-templates>
   </xsl:template>
   
   
   <xsl:template match="phrase[@text='source']">
      
<xsl:text>

         ------------------</xsl:text>

<xsl:text>

Source: </xsl:text>

      <xsl:value-of select="@work"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@line"/>
<xsl:text>
	&quot;</xsl:text>
      <xsl:copy-of select="."/>
      <xsl:text>&quot;</xsl:text>
      
      <xsl:for-each select="../phrase[@text='target']">
<xsl:text>

Target: </xsl:text>

      <xsl:value-of select="@work"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@line"/>
<xsl:text>
	&quot;</xsl:text>
      <xsl:copy-of select="."/>
      <xsl:text>&quot;</xsl:text>
         
      </xsl:for-each>

<xsl:text>

Matched on: </xsl:text>
      <xsl:value-of select="../@keypair"/>

<xsl:text>
Score: </xsl:text>
      <xsl:value-of select="../@score"/>
      
   </xsl:template>
   
</xsl:stylesheet>
