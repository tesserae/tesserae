#!/usr/bin/env perl

=head1 NAME

batch.enqueue.pl - CGI wrapper for batch.prepare.pl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

batch.prepare.pl
batch.run.pl

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.enqueue.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

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
}

# load Tesserae-specific modules

use lib $lib;

use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use DBI;
use File::Temp;
use CGI qw/:standard/;

#
# initialize variables
#

my @params = qw/
	source
	target
	unit
	feature
	stop
	stbasis
	dist
	dibasis/;

my %par;

#
# is this script being called from the web or cli?
#

my $query = CGI->new() || die "$!";

# html header

print header('-charset'=>'utf-8', '-type'=>'text/html');

#
# get user options
#

for (@params) {

	@{$par{$_}} = $query->param($_);
}

#
# create the config file for batch.prepare.pl
#

my $fh_config = generate_config_file(\%par);

#
# run batch.prepare.pl on the config file
#

my $session = init_session($fh_config->filename);

#
# add session to the queue
#

enqueue($session);

#
# redirect to status page
#

print html_redirect($session);

#
# subroutines
#

# run batch.prepare.pl and return session id

sub init_session {
	
	my $file_config = shift;
	
	my $script = catfile($fs{script}, 'batch', 'batch.prepare.pl');
	
	my $cmd = join(' ',
		$script,
		'--infile' => $file_config,
		'--parent' => $fs{tmp},
		'--get-session',
		'--quiet'
	);
	
	$session = `$cmd`;
	chomp $session;

	my @dir = File::Spec->splitdir($session);

	$session = $dir[-1];
	$session =~ s/tesbatch\.//;

	return $session;
}

#
# turn seconds into nice time
#

sub parse_time {

	my %name  = ('d' => 'day',
				 'h' => 'hour',
				 'm' => 'minute',
				 's' => 'second');
				
	my %count = ('d' => 0,
				 'h' => 0,
				 'm' => 0,
				 's' => 0);
	
	$count{'s'} = shift;
	
	if ($count{'s'} > 59) {
	
		$count{'m'} = int($count{'s'} / 60);
		$count{'s'} -= ($count{'m'} * 60);
	}
	if ($count{'m'} > 59) {
	
		$count{'h'} = int($count{'m'} / 60);
		$count{'m'} -= ($count{'h'} * 60);		
	}
	if ($count{'h'} > 23) {
	
		$count{'d'} = int($count{'h'} / 24);
		$count{'d'} -= ($count{'h'} * 24);
	}
	
	my @string = ();
	
	for (qw/d h m s/) {
	
		next unless $count{$_};
		
		push @string, $count{$_} . " " . $name{$_};
		
		$string[-1] .= 's' if $count{$_} > 1;
	}
	
	my $sep = " ";
	
	if (scalar @string > 1) {
			
		$string[-1] = 'and ' . $string[-1];
		
		$sep = ', ' if scalar @string > 2;
	}
	
	return join ($sep, @string);
}

#
# add a batch session to the queue
#

sub enqueue {

	my $session = shift;
	
	my $file_out = catdir($fs{tmp}, $session);
	
	my $file_queue = catfile($fs{data}, 'batch', 'queue', $session);

	open (my $fh, '>', $file_queue) or die "can't write queue $file_queue: $!";
	
	print $fh time;
	
	close ($fh);
}

#
# create a config file for batch.preprare.pl
#

sub generate_config_file {

	my ($par) = @_;
	my %par = %$par;
	
	my $fh = File::Temp->new();

	binmode $fh, ':utf8';
	
	for my $p (@params) {
	
		print $fh "[$p]\n";
		
		for my $val (@{$par{$p}}) {
		
			print $fh "$val\n";
		}
		
		print $fh "\n";
	}
	
	close ($fh);
	
	return ($fh);
}

#
# produce html redirecting to the status script
#

sub html_redirect {

	my $session = shift;

	my $redirect = "$url{cgi}/batch.status.pl?session=$session";
	
	my $html = <<END_HTML;
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
	<head>
		<title>Tesserae Batch Run Summary</title>
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin" />
		<!-- <meta http-equiv="Refresh" content="15: url='$redirect'"> -->
		<link rel="stylesheet" type="text/css" href="$url{css}/style.css" />
		</style>
	</head>
	<body>
		<h2>Your run has been queued</h2>
		
		<p>
			Your search has been entered into a queue to be processed. It has been assigned the session ID <strong>$session</strong>. You can check the status and estimated time to completion of your search, download results when finished, or cancel processing at any time by pointing your browser to the URL below.
		</p>
		
		<p>
			<a href="$redirect">$redirect</a>
		</p>
	</body>
</html>
END_HTML

	return $html;
}