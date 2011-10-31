use TessSystemVars;

# this array will hold a list of perl files to check

my @perl_files;

# first consult the cgi-bin directory
# and add any file with a .pl extension to the list

opendir (DH, $fs_cgi);

push @perl_files, (grep {/\.pl/ && -f} map { $fs_cgi.$_ } readdir DH);

closedir DH;

# now do the same for the perl directory

opendir (DH, $fs_perl);

push @perl_files, (grep {/\.pl/ && -f} map { $fs_perl.$_ } readdir DH);

closedir (DH);

#
# This array will hold a list of xsl files

my @xsl_files;

# get them from the xsl directory

opendir (DH, $fs_xsl);

push @xsl_files, (grep {/\.xsl/ && -f} map { $fs_xsl.$_ } readdir DH);

closedir (DH);

#
# Finally, a list of php files to change

my @php_files = ( $fs_html.'first.php' );

#
# make installation specific changes.

# first perl files.
#
# what they need is a single line at the beginning telling them where
# local modules will be stored
#

for my $file (@perl_files)
{	
	print STDERR "configuring $file\n";

	open IPF, "<$file";
	open OPF, ">$file.configured";
			
	while (my $line = <IPF>)
	{
		if ($line =~ /^use lib .+#\s*PERL_PATH/)
		{
			$line = "use lib '$fs_perl';	# PERL_PATH\n";
		}
		
		print OPF $line;
	}
	
	close IPF;
	close OPF;
	
	my $exec_string = 'mv ' . $file . '.configured ' . $file;
	system($exec_string);
}

#
# now the xsl stylesheets
#
# these store a bunch of pathnames as variables
# each one on a line marked by a comment
#

for my $file (@xsl_files)
{	
	print STDERR "configuring $file\n";

	open IPF, "<$file";
	open OPF, ">$file.configured";
			
	while (my $line = <IPF>)
	{
		
		if ($line =~ /<!--\s+URL_CGI/)
		{
			$line = "<xsl:variable name=\"url_cgi\" select=\"'$url_cgi'\"/>";
			$line .= '<!-- URL_CGI -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_CSS/)
		{
			$line = "<xsl:variable name=\"url_css\" select=\"'$url_css'\"/>";
			$line .= '<!-- URL_CSS -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_HTML/)
		{
			$line = "<xsl:variable name=\"url_html\" select=\"'$url_html'\"/>";
			$line .= '<!-- URL_HTML -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_IMAGES/)
		{
			$line = "<xsl:variable name=\"url_images\" select=\"'$url_images'\"/>";
			$line .= '<!-- URL_IMAGES -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_TEXT/)
		{
			$line = "<xsl:variable name=\"url_text\" select=\"'$url_text'\"/>";
			$line .= '<!-- URL_TEXT -->' . "\n";
		}
		
		print OPF $line;
	}
	
	close IPF;
	close OPF;
	
	my $exec_string = 'mv ' . $file . '.configured ' . $file;
	system($exec_string);
}


# finally the php files.
#
# they too store path names as variables

for my $file (@php_files)
{
	print STDERR "configuring $file\n";

        open IPF, "<$file";
        open OPF, ">$file.configured";

        while (my $line = <IPF>)
        {

                if ($line =~ /<!--\s+URL_CGI/)
                {
                        $line = "<?php \$url_cgi=\"$url_cgi\" ?>";
                        $line .= '<!-- URL_CGI -->' . "\n";
                }
                if ($line =~ /<!--\s+URL_CSS/)
                {
                        $line = "<?php \$url_css=\"$url_css\" ?>";
                        $line .= '<!-- URL_CSS -->' . "\n";
                }
                if ($line =~ /<!--\s+URL_HTML/)
                {
                        $line = "<?php \$url_html=\"$url_html\" ?>";
                        $line .= '<!-- URL_HTML -->' . "\n";
                }
                if ($line =~ /<!--\s+URL_IMAGES/)
                {
                        $line = "<?php \$url_images=\"$url_images\" ?>";
                        $line .= '<!-- URL_IMAGES -->' . "\n";
                }
                if ($line =~ /<!--\s+URL_TEXT/)
                {
                        $line = "<?php \$url_text=\"$url_text\" ?>";
                        $line .= '<!-- URL_TEXT -->' . "\n";
                }

                print OPF $line;
        }

        close IPF;
        close OPF;

        my $exec_string = 'mv ' . $file . '.configured ' . $file;
        system($exec_string);

}

my $exec_string = 'chmod +x ' . $fs_cgi . '*.pl';
system($exec_string);
