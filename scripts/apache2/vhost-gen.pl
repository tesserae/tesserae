#!/usr/bin/env perl

=head1 NAME

vhost-gen.pl - generate config file for apache2

=head1 SYNOPSIS

vhost-gen.pl [options]

=head1 DESCRIPTION

Generates a configuration file suitable for adding under "sites-available."

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

Assumes default URL paths. Modify the resulting file by hand if you've changed
these.

Future versions of Tesserae will be configured to use nginx rather than Apache.
This is just to support legacy versions of the code, especially that on sophia.

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is vhost-gen.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

my $lib;

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $pointer;
			
	while (1) {

		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-r $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$lib = <FH>;
			
			chomp $lib;
			
			last;
		}
									
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find .tesserae.conf!\n";
	}
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script


# initialize some variables

my $admin_email = 'root@localhost';
my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}


print <<END;

<VirtualHost *:80>
	ServerAdmin $admin_email

	<Directory />
		Options FollowSymLinks
		AllowOverride None
		Order deny,allow
		Deny from All
	</Directory>

	DocumentRoot $fs{html}/
	<Directory "$fs{html}">
		AllowOverride None
		Order allow,deny
		Allow from All		
	</Directory>
   
   Alias /doc/ $fs{doc}/
   <Directory "$fs{doc}">
      AllowOverride None
      Order allow,deny
      Allow from All
   </Directory>
		
	Alias /css/ $fs{css}/
	<Directory "$fs{css}">
		AllowOverride None
		Order allow,deny
		Allow from all		
	</Directory>

	Alias /images/ $fs{image}/
	<Directory "$fs{image}">
		AllowOverride None
		Order allow,deny
		Allow from all		
	</Directory>

	ScriptAlias /cgi-bin/ $fs{cgi}/
	<Directory "$fs{cgi}">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog \${APACHE_LOG_DIR}/tesserae.error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog \${APACHE_LOG_DIR}/tesserae.access.log combined

</VirtualHost>

END
