#!/usr/bin/env perl

=head1 NAME

syn-diagnostic-lookup.pl - look up a word in the dictionary

=head1 SYNOPSIS

name.pl [options] ARG1 [, ARG2, ...]

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<ARG1>

Description of what ARG1 does.

=item B<--option>

Description of what --option does.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

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

use CGI qw/:standard/;
use Storable;
use utf8;
use Encode;

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# initialize some variables

my $query;
my $html   = 0;
my $help   = 0;
my @feature  = qw/trans1 trans2/;

#
# check for cgi interface
#

my $cgi = CGI->new() || die "$!";

my $no_cgi = defined($cgi->request_method()) ? 0 : 1;

#
# get user options
#

if ($no_cgi) {
	
	GetOptions(
		'query=s'   => \$query,
		'feature=s' => \@feature,
		'help'      => \$help,
		'html'      => \$html
	);
	
	@feature = @feature[-2,-1];

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}
}
else {
	
	print header('-charset'=>'utf-8', '-type'=>'text/html');

	$query      = $cgi->param('query');
	$feature[0] = $cgi->param('feature1') || $feature[0];
	$feature[1] = $cgi->param('feature2') || $feature[1];
	$html = 1;
}

$query = Tesserae::standardize('grc', decode('utf8', $query));

#
# load up feature data
#

my %candidates = %{load_candidates()};

#
# print the output page
#

print_template($query, $html);

#
# subroutines
#

#
# retrieve definition for a word
#

sub load_def {
	
	my $token = shift;
	
	my $def = '';
	
	if (defined $token and $token ne '') {

		my $file = catfile($fs{data}, 'synonymy', 'dict-diagnostic', substr($token, 0, 1)); 

		if (-s $file) {
		
			if (open (my $fh, '<:utf8', $file)) {
			
				while (my $rec = <$fh>) {
					
					my ($head, $def_) = split(/::/, $rec);
					
					$head = Tesserae::standardize('grc', $head);
					
 					if ($head eq $token) {
					
						$def = $def_;
					
						last;
					}
				}
			}
		}
	}

	return $def;
}

#
# load stored translation feature data 
#

sub load_candidates {
	
	if ($no_cgi) {
	
		print STDERR "Loading feature data\n";
	}

	my %candidates;

	for my $feature (@feature) {
		
		my $file = catfile($fs{data}, 'common', join('.', 'grc', $feature, 'cache'));
		
		unless (-s $file) {
		
			die "Can't locate featureset $feature!";
		}

		$candidates{$feature} = retrieve($file);
		
		if ($no_cgi) {
			
			print STDERR "$feature has " . scalar(keys %{$candidates{$feature}}) . " keys\n";
		}
	}
	
	return \%candidates;
}

#
# return translation candidates for a word
#

sub get_candidates {
	
	my ($feature, $token) = @_;
	
	if (defined $candidates{$feature}{$token}) {
	
		return $candidates{$feature}{$token};
	}
	else {
		
		return [];
	}
}

#
# guess whether a word is greek
#

sub is_greek {

	my $token = shift;
	
	my @c = split(//, $token);
	
	for (@c) {
		
		if (ord($_) > 255) {

			return 1;
		}
	}
	
	return 0;
}

#
# template for output page
#

sub print_template {
	
	my ($query, $html) = @_;
	
	print html_header() if $html;
	
	print format_query($query, $html);
	
	print_results($feature[0], $query, $html);
	print_results($feature[1], $query, $html);
	
	print html_footer() if $html;
}

#
# html header and footer
# 

sub html_header {

	return <<END_HEAD;
<html>
	<head>
		<title>Query Results</title>
		<style type="text/css">
			div.query {
				border-bottom: 1px solid black;
			}
			div.result {
				border-bottom: 1px solid black;
			}
			div.head {
				font-weight: bold;
			}
			div.def {
				padding-bottom: 10px;
			}
			h1 {
				font-size: 100%;
				font-weight: normal;
				text-transform: uppercase;
			}
		</style>
	</head>
	<body>
	<div class="container">
END_HEAD
}

sub html_footer {
	
	return <<END_FOOT;
	</div>
	</body>
</html>
END_FOOT
}

#
# print the query token with its definition
#

sub format_query { 
	
	my ($query, $html) = @_;
	
	my $def = load_def($query);
	
	if ($html) {
		
		return <<END_HTML;
		<div class="query">
			<div class="head">$query</div>
			<div class="def">
				$def
			</div>
		</div>
END_HTML
	}
	else {
		
		return <<END_TEXT;
	query: $query
	definition: $def
END_TEXT
	}
}


#
# print translation candidates
#

sub print_results {
	
	my ($feature, $query, $html) = @_;
	
	if ($html) {
		
		print "<div class=\"result\">\n";
		print "<h1>$feature</h1>\n";
	}
	else {

		print "$feature:\n";
	}
	
	for my $res (@{get_candidates($feature, $query)}) {

		my $def = load_def($res);
	
		if ($html) {
		
			print "<div class=\"head\">$res</div>\n";
			print "<div class=\"def\">$def</div>\n";
		}
		else {
		
			print "$res: $def\n";
		}
	}
		
	if ($html) {
		
		print "</div>";
	}
	
	print "\n";
}