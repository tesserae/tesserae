use strict;
use warnings;

use Cwd qw/abs_path/;
use File::Spec::Functions;

use Term::UI;
use Term::ReadLine;

use FindBin qw($Bin);
use lib $Bin;

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

# make sure they're still where expected;
# if not, ask for new locations

print STDERR "Checking default paths...\n";

for (keys %fs) {

	$fs{$_} = check_fs($_);
}

print STDERR "\n";

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

# Ask user to confirm or change default paths

print STDERR "Setting URLs for web interface\n";
print STDERR "  (If you're not using this, accept the defaults)...\n";

check_urls();

print STDERR "\n";


#
# write config file
#

print STDERR "writing tesserae.conf\n";

write_config();

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
	
	my $l = maxlen(keys %fs) + 3;
	
	for (sort keys %fs) {
	
		print FH sprintf("%-${l}s = %s\n", "fs_$_", $fs{$_});
	}

	print FH "\n";
	print FH "# web interface URLs\n";
	
	$l = maxlen(keys %url) + 4;
	
	for (sort keys %url) {
	
		print FH sprintf("%-${l}s = %s\n", "url_$_", $url{$_});
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
