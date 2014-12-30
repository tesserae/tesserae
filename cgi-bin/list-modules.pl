#!/usr/bin/env perl
# Change the line above to match the path to perl on your server
###############################################################################
# This software is Copyright.
###############################################################################
# © Webnet77.com 2003-2007 All rights reserved.
###############################################################################
# INDEMNITY:
# THIS SOFTWARE IS PROVEDED WITHOUT ANY WARRANTY WHATSOEVER. USE ENTIRELY AT YOUR
# OWN RISK. NO LIABILITY WHATSOEVER, OF ANY NATURE, WILL BE ASSUMEND BY
# Webnet77.com, IT'S DISTRIBUTORS, RESELLERS OR AGENTS. SHOULD THE SOFTWARE
# DAMAGE YOUR SERVER, CAUSE YOU LOSS OR OTHER FINANCIAL DAMAGE, YOU AGREE YOU
# HAVE NO CLAIM AGINST Webnet77.com IT'S DISTRIBUTORS, RESELLERS OR AGENTS. IF
# YOU DO NOT ACCEPT THESE TERMS YOU MAY NOT USE THIS SOFTWARE.
###############################################################################
# Author: B.R. Maurer.
# Version 1.1.0 - Initial release April 2004
# Purpose of Software: List installed Perl Modules in a nice table.
# Contact information: http://www.Webnet77.com
###############################################################################

###############################################################################
#            *****~~~~~INSTALLATION~~~~~*****                                 #
###############################################################################
# 1. Unzip the file. There is only 1 file you need.
#    - list-modules.pl (the program)
#
# 4. Upload list-modules.pl to your server in ASCII MODE. NOTE ASCII mode!!!
#
# 5. CHMOD the file to 755.
#
# 6. If you did it all right, you should be ready to go.
#    Point your browser to http://yoursite.com/cgi-bin/list-modules.pl
###############################################################################


###############################################################################
#      !!!!!!!!!!!!!DO NOT CHANGE ANYTHING BEYOND THIS LINE!!!!!!!!!!!!!
###############################################################################
use CGI qw(:all);
use strict;

my @mods;
#-------------------------------------------------------------------------------
sub list_modules {
my ($n, $msg, $i);

  eval "use File::Find;";

  if ($@) {
    disp_html(qq|<b><font color="#FFFFFF">Sorry, <u>File::Find</u> is not installed on this server.</font></b>|);
  }

  find(\&wanted, @INC);

  @mods = sort {lc($a) cmp lc($b)} @mods;

  $n = @mods;

  $msg = qq|<p align="center"><font face="Arial" size="3" color="#000000"><b>Found: $n Modules</b></b></font></p>\n|;

  $msg .= qq|<div align="center"><center><table border="0" cellpadding="1" width="90%">\n|;
  $msg .= " <tr>\n";
  $msg .= qq|  <td valign="top"><font face="Arial,Arial" size="1" color="#FFFFFF">\n|;
  $i = 0;

  foreach (@mods) {
    $i++;
    $msg .= qq|         <a target="_blank" title="Query CPAN for $_" href="http://search.cpan.org/search?query=$_">$_</a><br>\n|;
    if (($i == int(($n / 3) + 2 / 3)) or ($i == int((2 * $n / 3) + 2 / 3 ))) {
      $msg .= qq|  </td>\n<td valign="top"><font face="Arial,Arial" size="1" color="#FFFFFF">\n|;
    }

  }

  $msg .= "  </td>\n </tr>\n</table>\n</center>\n</div>\n";
  &disp_html($msg);
}

#-------------------------------------------------------------------------------
sub wanted {

  if ($File::Find::name =~ /\.pm$/) {
    open(F, $File::Find::name) || return;
    while(<F>) {
      if (/^ *package +(\S+);/) {
        push (@mods, $1);
        last;
      }
    }
    close(F);
  }
}
#-------------------------------------------------------------------------------
sub disp_html {
my $mods = shift;


print qq|
<html>

<head>
<title>LIST MODULES</title>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="CHARSET" content="ISO-8859-1">
<style>
</style>
</head>

<body bgcolor="#FFFFFF" text="#000000" link="#a0a0a0" vlink="#FF0000" alink="#FF0000">

<center>
<table border="0" width="80%">
	<tr>
		<td width="100%" bgcolor="#000080">
		<p align="center"><b><font color="#FFFFFF" size="2" face="Arial">LIST PERL MODULES INSTALLED ON THIS SERVER</font></b></p>
		</td>
	</tr>
	<tr>
		<td width="100%"><br>
&nbsp;<table border="2" cellpadding="3" width="100%" id="table1" bgcolor="#EEEEEE" bordercolor="#000080" style="font-size: 8pt; font-family: Verdana">
			<tr>
				<td>$mods</td>
			</tr>
		</table>
		<p><br>
		</p>
		</td>
	</tr>
</table>
</center>
<p align="center"><i><font size="1" face="Arial">Free from <a style="text-decoration: none" title="Great hosting! Great service! Great pricing!" href="http://webnet77.com/">Webnet77.com</a></font></i></p>

</body>

</html>
|;

exit;
}
#-------------------------------------------------------------------------------
print header();
list_modules;
