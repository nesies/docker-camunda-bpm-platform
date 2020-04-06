<xsl:stylesheet
 version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:nsSrc="http://www.camunda.org/schema/1.0/BpmPlatform" 
>

<!-- add camunda.administrativeuser.plugin config -->
<xsl:template match="nsSrc:plugins">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" />
    <xsl:variable name="match" select="document($xml_conf)"/>
    <xsl:copy-of select="$match"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
