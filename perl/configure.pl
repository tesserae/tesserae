use Config;
use Cwd;
use File::Copy;

use FindBin qw($Bin);
use File::Spec::Functions;

use lib $Bin;
use TessSystemVars;

# this array will hold a list of perl files to check

my @perl_files;

# directories to search

my @perl_search = (
	$fs_cgi, 
	$fs_perl,
	$fs_test
	);

while (my $dir = shift @perl_search) {

	if (-d $dir) {
	
		opendir (DH, $dir);
		
		for (readdir DH) {

			if ( /\.pl|m$/ && -f catfile($dir, $_) ) {

				push @perl_files, catfile($dir, $_);
			}

			elsif ( /^[^\.]/   && -d catdir($dir, $_) ) { 
				
				push @perl_search, catdir($dir, $_);
			}
		}	
		
		closedir DH;
	}
}


#
# This array will hold a list of xsl files
#

my @xsl_files;

# get them from the xsl directory

opendir (DH, $fs_xsl);

push @xsl_files, (grep {/\.xsl/ && -f} map { catfile($fs_xsl, $_) } readdir DH);

closedir (DH);

#
# Finally, a list of php files to change
#

my @php_files = (

	catfile($fs_html, "defs.php"),
    catfile($fs_html, "frame.fulltext.php")
	);

#
# make installation specific changes.
#

# first perl files.
#
# what they need is a single line at the beginning telling them where
# local modules will be stored
#

for my $file (@perl_files) {

	print STDERR "configuring $file\n";

	open IPF, "<$file";
	open OPF, ">$file.configured";
			
	while (my $line = <IPF>) {
		
		if ($line =~ /^#!/) {
		
			$line = "#! $Config{perlpath}\n";
		}
	
		if ($line =~ /^use lib .+#\s*PERL_PATH/) {
		
			$line = "use lib '$fs_perl';	# PERL_PATH\n";
		}
		
		print OPF $line;
	}
	
	close IPF;
	close OPF;
	
	move( "$file.configured", $file) or die "move $file.configured $file failed: $!";
}

#
# make the cgi-bin files executable
#

my $exec_mode = oct("755");

for my $file (grep {/$fs_cgi/} @perl_files) {

	chmod $exec_mode, $file;
}

#
# now the xsl stylesheets
#
# these store a bunch of pathnames as variables
# each one on a line marked by a comment
#

for my $file (@xsl_files) {

	print STDERR "configuring $file\n";

	open IPF, "<", $file;
	open OPF, ">", "$file.configured";
			
	while (my $line = <IPF>) {
		
		if ($line =~ /<!--\s+URL_CGI/) {

			$line = "<xsl:variable name=\"url_cgi\" select=\"'$url_cgi'\"/>";
			$line .= '<!-- URL_CGI -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_CSS/) {
		
			$line = "<xsl:variable name=\"url_css\" select=\"'$url_css'\"/>";
			$line .= '<!-- URL_CSS -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_HTML/) {
		
			$line = "<xsl:variable name=\"url_html\" select=\"'$url_html'\"/>";
			$line .= '<!-- URL_HTML -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_IMAGE/) {
		
			$line = "<xsl:variable name=\"url_image\" select=\"'$url_image'\"/>";
			$line .= '<!-- URL_IMAGE -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_TEXT/) {
		
			$line = "<xsl:variable name=\"url_text\" select=\"'$url_text'\"/>";
			$line .= '<!-- URL_TEXT -->' . "\n";
		}
		
		print OPF $line;
	}
	
	close IPF;
	close OPF;
	
	move( "$file.configured", $file) or die "move $file.configured $file failed: $!";
}


# finally the php files.
#
# they too store path names as variables

for my $file (@php_files) {

	print STDERR "configuring $file\n";

	open IPF, "<$file";
	open OPF, ">$file.configured";

	while (my $line = <IPF>) {

		if ($line =~ /<!--\s+URL_CGI/) {

			$line = "<?php \$url_cgi=\"$url_cgi\" ?>";
			$line .= '<!-- URL_CGI -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_CSS/) {

			$line = "<?php \$url_css=\"$url_css\" ?>";
			$line .= '<!-- URL_CSS -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_HTML/) {

			$line = "<?php \$url_html=\"$url_html\" ?>";
			$line .= '<!-- URL_HTML -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_IMAGE/) {

			$line = "<?php \$url_image=\"$url_image\" ?>";
			$line .= '<!-- URL_IMAGE -->' . "\n";
		}
		if ($line =~ /<!--\s+URL_TEXT/) {

			$line = "<?php \$url_text=\"$url_text\" ?>";
			$line .= '<!-- URL_TEXT -->' . "\n";
		}
		if ($line =~ /<!--\s+FS_HTML/) {

			$line = "<?php \$fs_html=\"$fs_html\" ?>";
			$line .= '<!-- FS_HTML -->' . "\n";
		}

		print OPF $line;
	}

	close IPF;
	close OPF;

	move( "$file.configured", $file) or die "move $file.configured $file failed: $!";
}
