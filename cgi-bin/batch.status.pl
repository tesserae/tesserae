#!/usr/bin/env perl

#
# batch.status.pl
#

=head1 NAME

batch.status.pl - download results from batch.run.pl

=head1 SYNOPSIS

To be run as CGI from web interface.

=head1 DESCRIPTION

Check on status of a batch run. If results are still being calculated,
give an update on their progress. If they're done, give the user some
options for downloading them.

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.status.pl.

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

use CGI qw/:standard/;
use DBI;

# initialize some variables

my $help;
my $session;

#
# is this script being called from the web or cli?
#

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

# html header

print header('-charset'=>'utf-8', '-type'=>'text/html');

#
# get user options
#

# from command line

if ($no_cgi) {

	GetOptions(
		'help'      => \$help
	);

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}

	# get file to read from first cmd line arg

	$session = shift @ARGV;

	unless ($session) { pod2usage(1) }
}
	
# from web interface
	
else {

	$session  = $query->param('session');
	
	unless ($session) {
		
		die "no session specified from web interface";
	}
}


#
# check status
#

my ($status, $progress, $eta) = get_status($session);

#
# draw page
#

# header

print html_top($session, $status);

# status message

print html_status($status);

# progress bar

if (defined $progress) {

	print html_progress($progress, $eta);
}

# index of results, if batch is done

if (defined $status && $status == 1) {
	
	print html_results($session);
}

# page footer

print html_bottom();

#
# subroutines
#

sub get_status {

	my $session = shift;

	my $status;

	my $dir_session = catdir($fs{tmp}, 'tesbatch.' . $session);

	# if session directory doesn't exist, return DNE

	unless (-d $dir_session) {
		
		return (-2, undef, undef);
	}
	
	# otherwise, get status from session management files
		
	my $file_init   = catfile($fs{tmp}, 'tesbatch.' . $session, '.init');
	my $file_status = catfile($fs{tmp}, 'tesbatch.' . $session, '.status');
	
	my ($time_init,   $time_now);
	my ($count_final, $count_now);
	
	if (-e $file_init) {

		open (my $fh_init, '<', $file_init) or die "can't read $file_init: $!";
		
		my $line = <$fh_init>;
		
		($time_init, $count_final) = split(/\t/, $line);
		
		close ($fh_init);
	}
	
	if (-e $file_status) {
		
		open(my $fh_status, '<', $file_status) or die "can't read $file_status: $!";
		
		my $line = <$fh_status>;
		
		($time_now, $count_now, $status) = split(/\t/, $line)
	}
	
	# calculate progress, eta
	
	my ($progress, $eta);

	if (defined ($time_init and $time_now and $count_now and $count_final)) {
					
		my $elapsed = $time_now - $time_init;

		$progress = $count_now/$count_final;
	
		if ($progress < 1) {

			$eta = int(($elapsed / $progress) - $elapsed);
		}
	}
	
	return ($status, $progress, $eta);
}

# page head

sub html_top {
		
	my ($session, $status) = @_;
	
	my $refresh_link = "";
	
	unless (get_status($session)) {
	
		$refresh_link = '<meta http-equiv="Refresh" content="15">';
	}

	return <<END;
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
	<head>
		<title>Tesserae Batch Results</title>
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin" />
		<!-- $refresh_link -->
		<link rel="stylesheet" type="text/css" href="$url{css}/style.css" />
		<style type="text/css">
			table.results_index {
				
				margin-left: 3em;
				font-family: monospace;
			}
		</style>
	</head>
	<body>
		<h2>Status of Batch Results</h2>
		<p><strong>Session ID</strong>: $session</p>
		
END
}

sub html_status {

	my $status = shift;
	
	my $flag = (
		defined $status ?	(
			$status ==  0 ? 'PROCESSING' :
			$status ==  1 ? 'FINISHED'   :
			$status == -1 ? 'CANCELLED'  :
			'DNE'
		) :
		'PENDING'
	);
	
	my %message = (
		PENDING    => "Your search is currently queued and awaiting processing."
		               . "Please check back in a few minutes by reloading this page.",
		PROCESSING => "Your search is currently being processed. You can continue "
		               . "to monitor its progress by reloading this page.",
		FINISHED   => "Your search is finished! You can download the results below.",
		CANCELLED  => "This session has been cancelled. Please start over.",		
		DNE        => "The session you're looking for can't be found."
						   . "Please try again."
	);
	
	my $html = <<END_HTML;
	
	<div class="status">
		<p>Search status: $flag</p>
		<p>$message{$flag}</p>
	</div>
END_HTML

	return $html;
}

sub html_progress {

	my ($progress, $eta) = @_;
	
	my $html = '<div class="progress">';
	
	if (defined $progress) {
		
		$html .= "<p>" . int($progress * 100) . "% complete<br />";
	}
	else {
 		$html .= "Can't read progress, something must have gone wrong.";		
	}
	
	if (defined $eta) {
		
	 	$html .= "ETA: " . parse_time($eta) . "</p>";	
	}
	
 	$html .= '</div>';

	return $html;
}

sub html_results {

	my $session = shift;
	
	my $dir = catdir($fs{tmp}, 'tesbatch.' . $session);
				
	opendir(my $dh, $dir) or die "can't open results $dir: $!";
	
	my @tables = grep { /\.txt$/ && -s catfile($dir, $_)} 
					 readdir($dh);
		
	closedir($dh);
	
	my $html = <<END; 
	<div class="results">
	<p>Results available:</p>
	<form action="$url{cgi}/batch.dl.pl" method="get" id="Form1">
	<input type="hidden" name="session" value="$session" />
	<table class="results_index">
END
		
	for (@tables) {
		
		$html .= "<tr>"
				. "<td>$_</td>"
				. "<td><input type=\"hidden\" name=\"dl\" value=\"$_\" /></td>"
				. "</tr>";
	}
	
 	$html .= '</table>';
	$html .= '<p><input type="submit" name="download" value="Download Files" /></p>';
	$html .= '</div>';
	
	return $html;
}

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
# get the details of a session
#

sub details {

	my $session = shift;
	
	my $file_list = catdir($fs{tmp}, "tesbatch\.$session", '.list');

	my @params = qw/
		source
		target
		unit
		feature
		stop
		stbasis
		dist
		dibasis/;

	my @run;

	open (my $fh, '<:utf8', $file_list) or die "can't read list $file_list: $!";

	while (my $line = <$fh>) {
		
		$line =~ s/.*read_table.pl\s+//;
		
		my %par;

		while ($line =~ /--(\S+)\s+([^-]\S*)/g) {

			$par{$1} = $2;
		}
		
		push @run, [@par{@params}];
	}

	close($fh);
	
	return \@run;
}

#
# close <body> and <html> tags to finish page
# 

sub html_bottom {

	my $html = "\t</body>\n</html>\n";
	
	return $html;
}
