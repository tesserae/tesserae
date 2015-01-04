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

=item B<--fs_root> DIR

Set the root filesystem directory for Tesserae.

=item B<--fs_cgi> DIR

Set the filesystem location for cgi-bin.

=item B<--fs_data> DIR

Set the filesystem location for Tesserae's internal database.

=item B<--fs_doc> DIR

Set the filesystem location for documentation.

=item B<--fs_html> DIR

Set the filesystem location for the webroot.

=item B<--fs_script> DIR

Set the filesystem location for non-cgi scripts.

=item B<--fs_text> DIR

Set the filesystem location for text corpora.

=item B<--fs_tmp> DIR

Set the filesystem location for temporary files, including 
web-based session data.

=item B<--url_root> URL

Set the webroot url.

=item B<--url_cgi> URL

Set the url for cgi-bin.

=item B<--url_css> URL

Set the url for the stylesheet directory.

=item B<--url_doc> URL

Set the filesystem location for documentation.

=item B<--url_html> URL

Set the url for html/php files.

=item B<--url_image> URL

Set the url for the image directory.

=item B<--url_text> URL

Set the url for text corpora.

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

The Original Code is configure.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall, James Gawley

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
my $mode  = 'default';
my @py_lib;

#  assume tess root is parent of dir containing this script

my $fs_base = abs_path(catdir($Bin, '..'));

# locations as in the git repo

my %fs = (

	root   => $fs_base,
	cgi    => catfile($fs_base, 'cgi-bin'),
   css    => catfile($fs_base, 'css'),
	data   => catfile($fs_base, 'data'),
	doc    => catfile($fs_base, 'doc', 'html'),
	html   => catfile($fs_base, 'html'),
   image  => catfile($fs_base, 'images'),
	script => catfile($fs_base, 'scripts'),
	text   => catfile($fs_base, 'texts'),
	tmp    => catfile($fs_base, 'tmp')
);

# default URL is the public Tesserae at UB

my $url_base = 'http://tesserae.caset.buffalo.edu';

my %url = (

	root  => $url_base,
	cgi   => $url_base . '/cgi-bin',
	css   => $url_base . '/css',
	doc   => $url_base . '/doc/html',
	html  => $url_base . '',
	image => $url_base . '/images',
	text  => $url_base . '/texts'
);

# create options for setting individual paths

my %pathoptions;

for (keys %fs) {

	$pathoptions{"fs_$_=s"} = \$fs{$_};
}
for (keys %url) {

	$pathoptions{"url_$_=s"} = \$url{$_};
}

# get user options

GetOptions(
	'sophia'    => sub {$mode = 'sophia'},
	'quiet'     => \$quiet,
	'help'      => \$help,
	'py_lib=s'  => \@py_lib,
	%pathoptions
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# see whether fs{root}, url{root} have been changed,
# propagate change across paths

if ($fs{root} ne $fs_base) {

	for (keys %fs) {
	
		$fs{$_} =~ s/^$fs_base/$fs{root}/;
	}
}

if ($url{root} ne $url_base) {

	for (keys %url) {
	
		$url{$_} =~ s/^$url_base/$url{root}/;
	}
}

# fix any relative paths

for (keys %fs) {

	$fs{$_} =~ s/.*ROOT/$fs{root}/;
}

for (keys %url) {

	$url{$_} =~ s/.*ROOT/$url{root}/;
}


#
# descriptions of the various directories
#

my %desc = (
	root   => 'tesserae root',
	cgi    => 'cgi executables',
	css    => 'css stylesheets',
	data   => 'internal data',
	doc    => 'documentation folder',		
	html   => 'web documents',
	image  => 'images',
	script => 'ancillary scripts',
	text   => 'texts',
	tmp    => 'session data'
);


#
# interactive config
#

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
# write config file
#

print STDERR "writing tesserae.conf\n";

write_config();


#
# subroutines
#

sub check_urls {

	# set up terminal interface

	my $term = Term::ReadLine->new('myterm');

	# set length for descriptions

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
