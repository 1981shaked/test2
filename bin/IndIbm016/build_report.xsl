<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
 
    <xsl:output method="html"/>

    <xsl:template match="/">
        <HTML>
            <HEAD>

<TITLE>Build Report</TITLE>
<style type="text/css">
      body {
        font:normal 68% verdana,arial,helvetica;
        color:#000000;
      }
      table tr td, table tr th {
          font-size: 68%;
      }
      table.details tr th{
        font-weight: bold;
        text-align:left;
        background:#a6caf0;
      }
      table.details tr td{
        background:#eeeee0;
      }
      
      p {
        line-height:1.5em;
        margin-top:0.5em; margin-bottom:1.0em;
      }
      h1 {
        margin: 0px 0px 5px; font: 165% verdana,arial,helvetica
      }
      h2 {
        margin-top: 1em; margin-bottom: 0.5em; font: bold 125% verdana,arial,helvetica
      }
      h3 {
        margin-bottom: 0.5em; font: bold 115% verdana,arial,helvetica
      }
      h4 {
        margin-bottom: 0.5em; font: bold 100% verdana,arial,helvetica
      }
      h5 {
        margin-bottom: 0.5em; font: bold 100% verdana,arial,helvetica
      }
      h6 {
        margin-bottom: 0.5em; font: bold 100% verdana,arial,helvetica
      }
      .Error {
        font-weight:bold; color:red;
      }
      .Failure {
        font-weight:bold; color:purple;
      }
      .Properties {
        text-align:right;
      }
      </style>


 <script>
function divOnclick(id) {
	if(id.style.display == 'none') {
		id.style.display='';
	} else {
	id.style.display='none'
	}
}

var lastWin

function showDialogBox(obj) {

	var sURL = "about:blank";
	var sFeatures = "width=1000,height=600,scrollbars=1,status:no,resizable:yes,center:no,help:no";
	
	w=open('about:blank',"", sFeatures );
	w.document.write( obj.innerHTML );
	
	if (lastWin)
		lastWin.close(); 
	
	lastWin=w
		
}
</script>     



            </HEAD>
            <BODY>

<a name="top"></a>
<h1>Build Report Results on <xsl:value-of select="/TOTAL/Products/Product/Machine"/> (<xsl:value-of select="/TOTAL/Products/Product/Version"/>)</h1>
<table width="100%">
<tr>
<td align="left"></td><td align="right">Designed By The DevEnv Build team.</td></tr>
</table>
<hr size="1"> </hr>
<h2>Summary</h2>

                <TABLE width="95%" cellspacing="2" cellpadding="5" border="1" class="details">
                    <TR valign="top"><TH>Product Name</TH><TH>Machine</TH><TH>Version</TH><TH>Build Number</TH><TH>Build Product Number</TH><TH>Build Type</TH><TH>Build Start Time</TH><TH>Build Time</TH><TH>Success Rate</TH><TH>Refresh files</TH><TH>Deleted files</TH></TR>
                    <xsl:for-each select="/TOTAL/Products/Product">
                        <TR valign="top">
                            <TD><xsl:value-of select="Name"/></TD>
                            <TD><xsl:value-of select="Machine"/></TD>
                            <TD><xsl:value-of select="Version"/></TD>
                            <TD><xsl:value-of select="Build_number"/></TD>
														<TD><xsl:value-of select="Build_Product_number"/></TD>
                            <TD><xsl:value-of select="Build_Type"/></TD>
                            <TD><xsl:value-of select="Build_Start_Time"/></TD>
                            <TD><xsl:value-of select="Build_Time"/></TD>
                            <TD><xsl:value-of select="Success"/></TD>
                            <TD><xsl:value-of select="Refresh_files"/></TD>
                            <TD><xsl:value-of select="Deleted_files"/></TD>
                        </TR>
                    </xsl:for-each>
                </TABLE>




<table width="95%" border="0">
<tr>
<td style="text-align: justify;">
        Note: <i>failures</i> are anticipated and checked for with assertions while <i>errors</i> are unanticipated.
        </td>
</tr>
</table>
<hr align="left" width="95%" size="1"></hr>
<h2>Errors Details</h2>

<table width="95%" border="0">
<tr>
<td style="text-align: justify;">
        Note: <i>Click on the following links, in order to view the erros details.</i>.
</td>
</tr> 
</table>       

                <TABLE width="95%" cellspacing="2" cellpadding="5" border="1" class="details">
                    <TR valign="top"><TH>Project Name</TH><TH>Failure Type</TH><TH>Failure</TH><TH>Failure Rate</TH></TR>
                    <xsl:for-each select="/TOTAL/Projects/Project">
                        <TR valign="top">
                            <TD>
                              <A onclick="showDialogBox({Name})" style="cursor:hand;color:blue;text-decoration: underline;">
                                  <xsl:value-of select="Name"/>
                              </A>
                            </TD>


                            <TD><xsl:value-of select="Failure[@type='Type']"/></TD>
                            <TD><xsl:value-of select="Failure[@type='amount']"/></TD>
                            <TD><xsl:value-of select="Failure[@type='rate']"/></TD>
                        </TR>
                    </xsl:for-each>
                </TABLE>


<BR></BR><BR></BR><BR></BR><BR></BR><BR></BR>

                    <xsl:for-each select="/TOTAL/Error_Details/Project">

<div id="{@title}" style="display:none;">

<table width="102%" cellspacing="2" cellpadding="5" border="1" class="details">

                           <TR valign="top">
                           <TD style="color:blue">
                                  <xsl:value-of select="@title"/>
                           </TD>
                           </TR>

                        <xsl:for-each select="bb">
                           <TR ><TD style="color:red"><xsl:value-of select="@name"/></TD></TR>
                              <xsl:for-each select="error">
                                  <TR><TD><xsl:value-of select="@name"/></TD></TR>
                              </xsl:for-each>
                        </xsl:for-each>
</table>
</div>

                     </xsl:for-each>


<BR></BR><BR></BR>

<h2>Tasks names</h2>


<table width="95%" border="0">
<tr>
<td style="text-align: justify;">
        Note: <i>The following tasks have been participated in the build.</i>.
</td>
</tr>
</table>


                <TABLE width="95%" cellspacing="2" cellpadding="5" border="1" class="details">
                    <TR valign="top"><TH>Task Name</TH></TR>
                    <xsl:for-each select="/TOTAL/Tasks/Task">
                        <TR valign="top">
                            <TD><xsl:value-of select="Name"/></TD>
                        </TR>
                    </xsl:for-each>
                </TABLE>





<BR></BR><BR></BR>

<h2>Error Messaging info</h2>

<xsl:choose>
        <xsl:when test="/TOTAL/Error_Messaging/Project/Name != ''">

                <TABLE width="95%" cellspacing="2" cellpadding="5" border="1" class="details">
                    <TR valign="top"><TH>Project Name</TH><TH>Warning Message</TH></TR>
                    <xsl:for-each select="/TOTAL/Error_Messaging/Project">
                        <TR valign="top">
                            <TD><xsl:value-of select="Name"/></TD>
                            <TD><xsl:value-of select="Failure_Message"/></TD>
                        </TR>
                    </xsl:for-each>
                </TABLE>

        </xsl:when>
        <xsl:otherwise>

		<table width="95%" border="0">
		<tr>
			<td style="text-align: justify;">
        		<i>No error messages were found.</i>
     		   </td>
		</tr>
		</table>

        </xsl:otherwise>
</xsl:choose>


<BR></BR><BR></BR>


<h2>Statistics</h2>


                <TABLE width="95%" cellspacing="2" cellpadding="5" border="1" class="details">
                    <TR valign="top"><TH>Type</TH><TH>Total Files</TH><TH>Failure</TH><TH>Success Rate</TH></TR>
                    <xsl:for-each select="/TOTAL/Statistics/Record">
                        <TR valign="top">


                            <TD><xsl:value-of select="Name"/></TD>
                            <TD><xsl:value-of select="Total_Files"/></TD>
                            <TD><xsl:value-of select="Failure"/></TD>
                            <TD><xsl:value-of select="Success_rate"/></TD>
                        </TR>
                    </xsl:for-each>
                </TABLE>


            </BODY>
        </HTML>
    </xsl:template>

</xsl:stylesheet>
