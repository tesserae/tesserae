<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:variable name="url_text" select="'http://ahmik/~chris/tesserae/texts'"/><!-- URL_TEXT -->

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:text>&quot;Source Text&quot;,</xsl:text>
    <xsl:text>&quot;</xsl:text>
    <xsl:value-of select="concat($url_text, results/@source)"/>
    <xsl:text>&quot;</xsl:text>
<xsl:text>
</xsl:text>

    <xsl:text>&quot;Target Text&quot;,</xsl:text>
    <xsl:text>&quot;</xsl:text>
    <xsl:value-of select="concat($url_text, results/@target)"/>
    <xsl:text>&quot;</xsl:text>
<xsl:text>
</xsl:text>

    <xsl:apply-templates select="results"/>
  </xsl:template>
   

  <xsl:template match="results">

    <xsl:text>Session,</xsl:text>
    <xsl:text>&quot;</xsl:text>
    <xsl:value-of select="@sessionID"/>
    <xsl:text>&quot;</xsl:text>
<xsl:text>
</xsl:text>

    <xsl:text>Comments,</xsl:text>
    <xsl:text>&quot;</xsl:text>
    <xsl:value-of select="comments"/>
    <xsl:text>&quot;</xsl:text>

<xsl:text>

</xsl:text>

    <xsl:text>"Source Loc","Target Loc","Source Phrase","Target Phrase","Matched On","Score"</xsl:text>
<xsl:text>
</xsl:text>

    <xsl:apply-templates select="tessdata/phrase[@text='source']">
               <xsl:sort select="substring-before(@line,'.')" data-type="number"/>
               <xsl:sort select="substring-after(@line,concat(substring-before(@line,'.'),'.'))" data-type="number"/>
      </xsl:apply-templates>
   </xsl:template>
   
   
   <xsl:template match="phrase[@text='source']">

      <xsl:variable name="loca"> 
         <xsl:text>&quot;</xsl:text>
         <xsl:value-of select="@work"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="@line"/>
         <xsl:text>&quot;</xsl:text>
      </xsl:variable>

      <xsl:variable name="phrasea">	
         <xsl:text>&quot;</xsl:text>
         <xsl:copy-of select="."/>
         <xsl:text>&quot;</xsl:text>
      </xsl:variable>
      
      <xsl:for-each select="../phrase[@text='target']">

         <xsl:copy-of select="$loca"/>

         <xsl:text>,</xsl:text>

         <xsl:text>&quot;</xsl:text>
         <xsl:value-of select="@work"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="@line"/>
         <xsl:text>&quot;</xsl:text>

         <xsl:text>,</xsl:text>

         <xsl:copy-of select="$phrasea"/>

         <xsl:text>,</xsl:text>
	
         <xsl:text>&quot;</xsl:text>
         <xsl:copy-of select="."/>
         <xsl:text>&quot;</xsl:text>
         
         <xsl:text>,</xsl:text>

         <xsl:text>&quot;</xsl:text>
         <xsl:value-of select="../@keypair"/>
         <xsl:text>&quot;</xsl:text>

         <xsl:text>,</xsl:text>
         <xsl:value-of select="../@score"/>

<xsl:text>
</xsl:text>

      </xsl:for-each>

   </xsl:template>
   
</xsl:stylesheet>
