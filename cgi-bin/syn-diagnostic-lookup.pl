#!/usr/bin/env perl

=head1 NAME

syn-diagnostic-lookup.pl - look up a translation candidates in the dictionary

=head1 SYNOPSIS

syn-diagnostic-lookup.pl [options]

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--target>

The text whose stems we want to index. Use '*' to list all the stems in the corpus.

=item B<--feature> FEATURE

Specify the feature set to check; repeat to set both feature sets.

=item b<--query> STEM

Specify the greek stem to check against the translation dictionaries.

=item B<--auth> USER

Initiate manual-correction mode. I<USER> should be one of cf, jg, kc, am, nc.

=item B<--html>

Print the same HTML output that would be sent to a web user.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is syn-diagnostic-lookup.pl.

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

use CGI qw/:standard/;
use CGI::Session;
use DBI;
use Storable;
use utf8;
use Encode;

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# initialize some variables

my $target   = 'homer.iliad';
my $query;
my @feature  = qw/trans1 trans2 trans2mws IBM/;
my $auth;
my $html     = 0;
my $help     = 0;

#
# check for cgi interface
#

my $cgi = CGI->new() || die "$!";
my $session;
my $no_cgi = defined($cgi->request_method()) ? 0 : 1;

#
# get user options
#

if ($no_cgi) {
	
	GetOptions(
		'query=s'   => \$query,
		'feature=s' => \@feature,
		'target=s'  => \$target,
		'auth=s'    => \$auth,
		'help'      => \$help,
		'html'      => \$html
	);
	
	@feature = @feature[-4, -3, -2,-1];

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}
}
else {
	
	$session = CGI::Session->new(undef, $cgi, {Directory => '/tmp'}, {name=>'syn-diagnostic'});
	
	print $session->header('-charset'=>'utf-8', '-type'=>'text/html');

	$target     = $cgi->param('target')   || $session->param('target')   || $target;
	$query      = $cgi->param('query')    || $session->param('query');
	$feature[0] = $cgi->param('feature1') || $session->param('feature1') || $feature[0];
	$feature[1] = $cgi->param('feature2') || $session->param('feature2') || $feature[1];
	$feature[2] = $cgi->param('feature3') || $session->param('feature3') || $feature[2];
	$feature[3] = $cgi->param('feature4') || $session->param('feature4') || $feature[3];
 	$auth       = $cgi->param('auth')     || $session->param('auth');
	$html = 1;
}

$query = Tesserae::standardize('grc', decode('utf8', $query));

#
# load up feature data
#

my %candidates = %{load_candidates()};

my $dbh = init_db();
my %done = %{check_done()};

if ($done{$query}) { $auth = undef }

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
					
					my $lang = is_greek($head) ? 'grc' : 'la';
					
					$head = Tesserae::standardize($lang, $head);
					
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
	
	print_results(0, $query, $html);
	print_results(1, $query, $html);
	print_results(2, $query, $html);
	print_results(3, $query, $html);	
	
	print html_footer() if $html;
}

#
# html header and footer
# 

sub html_header {

	my $form_head = '';
	
	if ($auth) {
		
		my %freq = load_lex($target);
		
		my $freq = sprintf("%.5f", $freq{$query});
	
		$form_head = "<form action=\"$url{cgi}/syn-diagnostic-submit.pl\" method=\"POST\" target=\"_top\">\n"		
	              . "<input type=\"hidden\" name=\"auth\"     value=\"$auth\"       />\n"
					  . "<input type=\"hidden\" name=\"query\"    value=\"$query\"      />\n"
					  . "<input type=\"hidden\" name=\"feature1\" value=\"$feature[0]\" />\n"
					  . "<input type=\"hidden\" name=\"feature2\" value=\"$feature[1]\" />\n"
					  . "<input type=\"hidden\" name=\"feature3\" value=\"$feature[2]\" />\n"					  
					  . "<input type=\"hidden\" name=\"feature4\" value=\"$feature[3]\" />\n"
					  . "<input type=\"hidden\" name=\"target\"   value=\"$target\"     />\n";
	}

	return <<END_HEAD;
<html>
	<head>
		<title>Query Results</title>
		<link href="$url{css}/style.css" rel="stylesheet" type="text/css" />
		<style type="text/css">
			div.query {
				position: relative;
				border-bottom: 1px solid black;
			}
			div.feature {
				border-bottom: 1px solid black;	
			}
			div.result {
				position: relative;
			}
			div.head {
				font-weight: bold;
			}
			div.def {
				padding-bottom: 10px;
			}
			div.input {
			
				position:absolute;
				top: 0px;
				right: 0px;
				width: 100px;
				text-transform: uppercase;
				font-size: 90%;
			}
			div.submit {
				
				text-align: right;
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
		$form_head
END_HEAD
}

sub html_footer {
	
	my $form_foot = $auth ? '<div class="submit"><input type="submit" value="Submit" /></div></form>' : '';
	
	return <<END_FOOT;
		$form_foot
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
	
	my $template = "";
	
	if ($html) {
		
		my $set_pos = '';
		
		if ($auth) {
			
			$set_pos = <<END_SELECT;
			<div class="input">
				<select name="pos">
					<option value="noun">noun</option>
					<option value="verb">verb</option>
					<option value="ptcl">particle</option>					
					<option value="conj">conjunction</option>
					<option value="prep">preposition</option>
					<option value="adjt">adjective</option>					
					<option value="pron">pronoun</option>
					<option value="advb">adverb</option>
					<option value="name">name</option>
					<option value="unkn">ambiguous</option>
				</select>
			</div>
END_SELECT
		}
		
 		$template .= <<END_HTML;
		<div class="query">
			<div class="head">$query</div>
			$set_pos
			<div class="def">
				$def
			</div>
		</div>
END_HTML
	}
	else {
		
 		$template .= <<END_TEXT;
	query: $query
	definition: $def
END_TEXT
	}
	
	return $template;
}


#
# print translation candidates
#

sub print_results {
	
	my ($f, $query, $html) = @_;
	
	if ($html) {
		
		print "<div class=\"feature\">\n";
		print "<h1>$feature[$f]</h1>\n";
	}
	else {

		print "$feature[$f]:\n";
	}
	
	my @candidate = @{get_candidates($feature[$f], $query)};
	
	for my $i (0,1) {
		
		my $head = '';
		my $def  = '';
		
		if (defined $candidate[$i]) {
		
			$head = $candidate[$i];
			$def  = load_def($head);
		}

		if ($html) {
			
			print "<div class=\"result\">\n";
			print "<div class=\"head\">$head</div>\n";
						
			if ($auth) {
			
				my $subscript = sprintf("%d%s", $f + 1, $i ? 'b' : 'a');
				my $value = $head || 'NULL';
			
 				print "<div class=\"input\">\n";
				print "<input type=\"hidden\"   name=\"la_$subscript\" value=\"$value\">\n";
	
				if ($head) {
					print "<input type=\"checkbox\" name=\"v_$subscript\">valid</input> ";
					print "<input type=\"checkbox\" name=\"p_$subscript\">pos</input>\n";
				}
				
				print "</div>\n";
			}

			print "<div class=\"def\">$def</div>\n";			
			print "</div>\n";
		}
		else {
		
			print "$head: $def\n" if $head;
		}
	}
		
	if ($html) {
		
		print "</div>";
	}
	
	print "\n";
}

#
# get the list of words for the target text
#

sub load_lex {
	
	my $target = shift;

	my $file;

	if ($target eq '*') {

		$file = catfile($fs{data}, 'common', 'grc.stem.freq');
	}
	else {

		$file = catfile($fs{data}, 'v3', 'grc', $target, $target . '.freq_stop_stem');
	}

	return Tesserae::stoplist_hash($file);
}

#
# connect to database
#

sub init_db {

	# connect to database

	my $file_db = catfile($fs{tmp}, 'syn-diagnostic.db');
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file_db", "", "");

	# check to make sure table exists
	
	my $sth = $dbh->prepare(
		'select name from sqlite_master where type="table";'
	);
	
	$sth->execute;
	
	my $exists = 0;

	while (my $table = $sth->fetchrow_arrayref) {
		
		if ($table->[0] eq 'results') {
		
			$exists = 1;
		}
	}
		
	# create it if it doesn't
	
	unless ($exists) {

		die "table results doesn't exist!";
	}

	return $dbh;
}

#
# see which words already have entries
#

sub check_done {

	my %done;
	
	if ($auth) {
	
		print STDERR "checking validation progress\n" if $no_cgi;

		my $aref = $dbh->selectall_arrayref('select * from results;');
	
		for my $row (@$aref) {
	
			my $grc = $row->[0];
			
			$grc = Tesserae::standardize('grc', decode('utf8', $grc));
			
			if ($grc) {
				$done{$grc} = 1;
			}
		}
	}
	
	return \%done;
}
