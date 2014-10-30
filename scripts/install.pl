#!/usr/bin/env perl

=head1 install.pl

install.pl - install Tesserae

=head1 SYNOPSIS

install.pl [options]

=head1 DESCRIPTION

This script is to be run after configure.pl. Program components are
moved from default locations to those specified in tesserae.conf.
Pointer files back to tesserae.conf are placed in the newly-installed
directories. 

This script also generates defs.php, which is necessary for the web
interface.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

Doesn't actually move any files. If you want them installed other than
in the default locations, you have to move them yourself.

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is install.pl.

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
	
	unless (-e catfile($lib, 'tesserae.conf')) {
	
		warn "Can't find tesserae.conf. Try running configure.pl";
		die;
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

use Config;

# use File::Copy::Recursive qw/dircopy/;

# initialize some variables

my $help = 0;
my $clean = 0;
my $quiet = 0;

# locations as in the git repo

my $fs_base = abs_path(catdir($Bin, '..'));

my %fs_orig = (

	root   => $fs_base,
	cgi    => catfile($fs_base, 'cgi-bin'),
	data   => catfile($fs_base, 'data'),
	doc    => catfile($fs_base, 'doc', 'html'),
	html   => catfile($fs_base, 'html'),
	script => catfile($fs_base, 'scripts'),
	text   => catfile($fs_base, 'texts'),
	tmp    => catfile($fs_base, 'tmp')
);

# get user options

GetOptions(
	'quiet' => \$quiet,
	'clean' => \$clean,
	'help'  => \$help
);


# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

#
# install 
#

for my $key (keys %fs_orig) {

	# print join(' => ', $fs_orig{$key}, $fs{$key}) . "\n";

	if (defined($fs{$key}) and $fs{$key} ne $fs_orig{$key}) {
	
		# dircopy($fs_orig{$key}, $fs{$key});
		
		print STDERR "NB: Please copy $fs_orig{$key} => $fs{key} manually!\n";
	}
}

#
# write pointer to config for cgi-bin
#

write_pointer($fs{cgi});
write_pointer($fs{script});

#
# create var definition files for php
#

create_php_defs(catfile($fs{html}, 'defs.php'));

#
# install documentation
#

# get perl path (copied from example at `perldoc perlvar`)
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
	$secure_perl_path .= $Config{_exe}
	unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

my $file_script = catfile($fs{script}, 'doc_gen.pl');
`$secure_perl_path $file_script`;


#
# subroutines
#

# write a pointer to the config file

sub write_pointer {

	my $dir = shift;
	
	my $file = catfile($dir, '.tesserae.conf');
	
	open (FH, ">", $file) or die "can't write $file: $!";
	
	print STDERR "writing $file\n" unless $quiet;
	
	print FH $fs{script} . "\n";
	
	close FH;
}

#
# Create defs.php, 
#   containing system vars used by php files
#

sub create_php_defs {

	my $file = shift;

	open (FH, ">:utf8", $file) or die "can't create file $file: $!";

	print STDERR "writing $file\n";
	
	print FH <<END;
		
<?php \$url_html  = "$url{html}" ?>
<?php \$url_css   = "$url{css}" ?>
<?php \$url_cgi   = "$url{cgi}" ?>
<?php \$url_doc   = "$url{doc}" ?>
<?php \$url_image = "$url{image}" ?>
<?php \$url_text  = "$url{text}" ?>
<?php \$fs_html   = "$fs{html}" ?>

END
	
	close FH;
	return;
}

