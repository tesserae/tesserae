#!/usr/bin/env perl

=head1 NAME

configure.pl - create tesserae.conf

=head1 SYNOPSIS

configure.pl [options]

=head1 DESCRIPTION

This script allows the user to interactively set configuration options for Tesserae,
in particular, paths to different elements of the local installation.  It then creates
I<tesserae.conf> in the I<scripts/> directory, as well as pointers to the configuration
file in I<scripts/> and I<cgi-bin/>.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--default>

Don't run interactively, just assume that everything is installed as it is in the Git
repository.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

scripts/install.pl

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is name.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s):

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;
use Term::UI;
use Term::ReadLine;

# initialize some variables

my $help  = 0;
my $quiet = 0;
my $mode  = 'interactive';

# get user options

GetOptions(
	'default' => sub {$mode = 'default'},
	'sophia'  => sub {$mode = 'sophia'},
	'quiet'   => \$quiet,
	'help'    => \$help);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

#
# set up terminal interface
#

my $term = Term::ReadLine->new('myterm');

#
# descriptions of the various directories
#

my %desc = (

	base   => 'tesserae root',
	cgi    => 'cgi executables',
	css    => 'css stylesheets',
	data   => 'internal data',
	html   => 'web documents',
	image  => 'images',
	script => 'ancillary scripts',
	text   => 'texts',
	tmp    => 'session data',
	xsl    => 'xsl stylesheets');

#
# filesystem paths
#

#  assume tess root is parent of dir containing this script

my $fs_base = abs_path(catdir($Bin, '..'));

# locations as in the git repo

my %fs = (

	cgi    => 'cgi-bin',
	data   => 'data',
	html   => 'html',
	script => 'scripts',
	text   => 'texts',
	tmp    => 'tmp',
	xsl    => 'xsl');

if ($mode eq 'sophia') {

	$fs{html} = '';
}

# make sure directories are still where expected;
# if not, ask for new locations

print STDERR "Checking default paths...\n" unless $quiet;

for (keys %fs) {

	$fs{$_} = check_fs($_);
}

print STDERR "\n" unless $quiet;

#
# paths to important directories
# for the web browswer
#

# default is the public Tesserae at UB

my $url_base = 'http://tesserae.caset.buffalo.edu';

my %url = (

	cgi   => $url_base . '/cgi-bin',
	css   => $url_base . '/css',
	html  => $url_base . '',
	image => $url_base . '/images',
	text  => $url_base . '/texts',
	xsl   => $url_base . '/xsl');

if ($mode eq 'interactive') {

	# Ask user to confirm or change default paths
	
	unless ($quiet) {
	
		print STDERR "Setting URLs for web interface\n";
		print STDERR "  (If you're not using this, accept the defaults)...\n";
	}
	
	check_urls();
	
	print STDERR "\n" unless $quiet;
}

#
# additional search paths for local python modules
#

my @py_lib;

if ($mode eq 'sophia') {

	push @py_lib, '/usr/local/tesserae/lib/python2.6/site-packages/gensim-0.8.6-py2.6.egg';
}

print STDERR "Configuring local python libraries\n" unless $quiet;

#
# write config file
#

print STDERR "writing tesserae.conf\n";

write_config();

#
# write pointer to config for cgi-bin
#

write_pointer($fs{cgi});
write_pointer($fs{script});

#
# create var definition files for php and xsl
#

create_php_defs(catfile($fs{html}, 'defs.php'));
create_xsl_defs(catfile($fs{xsl},  'defs.xsl'));

#
# subroutines
#

sub check_fs {

	my $key = shift;

	# append the directory name to the assumed base tess dir

	my $path = catdir($fs_base, $fs{$key});
	
	$path = abs_path($path);
	
	while (! -d $path) {
	
		my $message = 
	
			"Can't find default path for $desc{$key}:\n"
			. "  $path doesn't exist or is not a directory\n"
			. "Have you moved this directory?\n";

		my $prompt = "Enter the new path, or nothing to quit: ";
		
		my $reply = $term->get_reply(

			prompt   => $prompt,
			print_me => $message) || "";
				
		$reply =~ /(\S+)/;
		
		if ($path = $1) {
		
			$path = abs_path($path);
		}
		else {
		
			print STDERR "Terminating.\n";
			print STDERR "NB: Tesserae is not configured properly!\n";
			exit;
		}
	}
	
	print STDERR "  Setting path for $desc{$key} to $path\n";
	
	return $path;
}

sub check_urls {

	my $l = maxlen(@desc{keys %url}) + 1;
	
	DIALOG_MAIN: for (;;) {
	
		my $status = "Confirm URL assignments:\n";
		
		my @choices;
		
		for (sort keys %url) {
			
			push @choices, sprintf("%-${l}s %s", $desc{$_} . ':', $url{$_});
		}

		$choices[-1] .= "\n";

		push @choices, (
			
			'Change webroot for all URLs',
			'Done');
	
		my $prompt = 'Any changes? ';
		
		my $reply = $term->get_reply(
		
			prompt   => $prompt, 
			choices  => \@choices,
			print_me => $status);
			
		for ($reply) {
		
			if (/done/i) {

				last DIALOG_MAIN;
			}
			if (/root/i) {
			
				# ask for new web root
			
				my $reply = $term->get_reply(
				
					prompt  => 'new webroot: ',
					default => $url_base);

				# add http:// if not present

				if ($reply !~ /^http:\//) {
				
					$reply = 'http://' . $reply;
				}
				
				# strip final / and double //
				
				$reply =~ s/([^:])\/+/$1\//g;
				$reply =~ s/\/$//;

				# substitute in all urls that contain the webroot

				for (values %url) {
				
					s/^$url_base/$reply/;
				}
				
				# remember that this is what should be replaced next time
				
				$url_base = $reply;
				
				next DIALOG_MAIN;
			}
				
			my $change = "";		
				
			for (sort keys %url) {
				
				if ($reply =~ /$desc{$_}/i) { $change = $_ }
			}
				
			if ($change) {
				
				# ask for a new url
			
				my $reply = $term->get_reply(
				
					prompt  => "new URL for $desc{$change}? ",
					default => $url{$change});
					
				# try to guess whether this is relative to
				# existing web root or an absolute address
					
				unless ($reply =~ /^http:\/\//) {
				
					my $base = (split('/', $reply))[0] || "";
					
					if ($base =~ /\./) {
					
						$reply = 'http://' . $reply;
					}
					else {
					
						$reply = join('/', $url_base, $reply);
					}
				}
										
				# strip final / and double //
					
				$reply =~ s/([^:])\/+/$1\//g;
				$reply =~ s/\/$//;
										
				$url{$change} = $reply;
			}
		}
	}	
}


#
# write the configuration file
#

sub write_config {

	my $file = catfile($Bin, 'tesserae.conf');
	
	open (FH, ">:utf8", $file) or die "can't write $file: $!";
	
	print FH "# tesserae.conf\n";
	print FH "#\n";
	print FH "# Configuration file for Tesserae\n";
	print FH "# generated automatically by configure.pl\n";
				
	print FH "\n";
	print FH "# filesystem paths\n";
	print FH "[path_fs]\n";
	
	my $l = maxlen(keys %fs);
	
	for (sort keys %fs) {
	
		print FH sprintf("%-${l}s = %s\n", $_, $fs{$_});
	}

	print FH "\n";
	print FH "# web interface URLs\n";
	print FH "[path_url]\n";
	
	$l = maxlen(keys %url);
	
	for (sort keys %url) {
	
		print FH sprintf("%-${l}s = %s\n", $_, $url{$_});
	}
	
	print FH "\n";
	print FH "# local python search path\n";
	print FH "[py_lib]\n";
	
	for (@py_lib) {
	
		print FH $_ . "\n";
	}
	
	close FH;
}

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
# Create defs.xsl,
#    containing system vars used by xsl files
#

sub create_xsl_defs {

	my $file = shift;

	open (FH, ">:utf8", $file) or die "can't create file $file: $!";
	
	print STDERR "writing $file\n";
	
	print FH <<END;
	
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:variable name="url_cgi"   select="'$url{cgi}'" />
	<xsl:variable name="url_css"   select="'$url{css}'" />
	<xsl:variable name="url_html"  select="'$url{html}'" />
	<xsl:variable name="url_image" select="'$url{image}'" />
	<xsl:variable name="url_text"  select="'$url{text}'" />
	
</xsl:stylesheet>
END

	close FH;
	return;
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
<?php \$url_image = "$url{image}" ?>
<?php \$url_text  = "$url{text}" ?>
<?php \$fs_html   = "$fs{html}" ?>

END
	
	close FH;
	return;
}


# figure out the max length of a bunch of strings

sub maxlen {

	my @s = @_;
	
	my $maxlen = 0;
	
	for (@s) {
	
		if (defined $_ and length($_) > $maxlen) {
		
			$maxlen = length($_);
		}
	}
	
	return $maxlen;
}
