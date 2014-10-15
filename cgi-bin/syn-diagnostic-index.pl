#!/usr/bin/env perl

#
# This is a template for how Tesserae scripts should begin.
#
# Please fill in documentation notes in POD below.
#
# Don't forget to modify the COPYRIGHT section as follows:
#  - name of the script where it says "The Original Code is"
#  - your name(s) where it says "Contributors"
#

=head1 NAME

syn-diagnostic-index.pl - show which stems in a text have translations 

=head1 SYNOPSIS

syn-diagnostic-index.pl [options]

=head1 DESCRIPTION

This is normally run only as a cgi from the web interface.

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

The Original Code is syn-diagnostic-index.pl.

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
use Storable;
use utf8;
use DBI;
use Encode;

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# initialize some variables

my $target   = 'homer.iliad';
my @feature  = qw/trans1 trans2 trans2mws IBM/;
my $auth;
my $query;
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
		'target=s'  => \$target,
		'feature=s' => \@feature,
		'query=s'   => \$query,
		'auth=s'    => \$auth,
		'help'      => \$help,
		'html'      => \$html
	);

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

my $dbh = init_db();
my %done = %{check_done()};

print_header();

my %index = %{load_lex($target)};
my %hits = %{check_hits()};
export_lex();

print_footer();


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
# check stored translation feature data 
#

sub check_hits {
		
	if ($no_cgi) {
	
		print STDERR "Loading feature data\n";
	}

	if ($html) {
	
		print "<div class=\"summary\">\n";
		print "<table>\n";
	}

	my %hits;
	
	for my $feature (@feature) {
		
		my $file = catfile($fs{data}, 'common', join('.', 'grc', $feature, 'cache'));
		
		unless (-s $file) {
		
			die "Can't locate featureset $feature!";
		}

		my %candidates = %{retrieve($file)};
		
		if ($no_cgi) {
			
			print STDERR "$feature has " . scalar(keys %candidates) . " keys\n";
		}
	
		my $count = 0;
		
		for my $token (keys %index) {
		
			if (defined $candidates{$token}) {
			
				$hits{$token}{$feature} = scalar(@{$candidates{$token}});
				$count ++;
			}
		}
		  
		my $rate = sprintf("%.0f", 100 * $count / scalar(keys %index));
		
		if ($html) {
		
			print "<tr><td>$feature</td><td>$rate\%</td>\n";
		}
		else {
		
			print "$feature: $rate\n"; 
		}
	}
	
	if ($html) {
	
		print "</table>\n";
		print "</div>\n";
	}
	
	return \%hits;
}


#
# page header
#

sub print_header {
	
	if ($html) {

		print <<END_HEAD;
<html>
	<head>
		<link href="$url{css}/style.css" rel="stylesheet" type="text/css" />
		<style type="text/css">
			tr {
				padding: 4px 3px;
			}
 			a {
				text-decoration: none;
			}
			a:link, a:visited {
				color: #0000B0;
			}
			a.done {
				color:grey;
			}
			div.summary {
				margin-bottom:10px;
			}
			div.back {
				padding:3px 3px 8px 3px;
			}
		</style>
	</head>
	<body>
	<div class="back">
		<a style="color:grey;" href="$url{html}/experimental.php" target="_top">Back to Tesserae</a>
	</div>
	<div>
END_HEAD

		print select_list($target) unless $auth;
	}
	else {
	
		print "Lexicon for $target\n";
	}
}

sub print_footer {

	if ($html) {

		print <<END_FOOT;
	</div>
</html>
END_FOOT
	}
}


#
# draw the index
#

sub export_lex {

	if ($html) {
		
		print "<div class=\"index\"><table>\n";
		print "<tr><th>freq(\%)</th><th>stem</th><th>$feature[0]</th><th>$feature[1]</th><th>$feature[2]</th><th>$feature[3]</th></tr>\n";	 
	}
				
	for my $token (sort keys %index) {
#	To sort by frequency values reinstate this code:	"for my $token (sort {$index{$b} <=> $index{$a}} keys %index) {" –JG
		my $template;
	
		my $freq = sprintf("%.2f", 100 * $index{$token});
	
		if ($html) {
			
			my $flag = '';
			
			if ($done{$token}) {
				 $flag = ' class="done"';
			}
			
			print "<td>$freq</td>";
			print "<td>";
			print "<a$flag href=\"$url{cgi}/syn-diagnostic-lookup.pl?query=$token\" target=\"right\">";
			print $token;
			print '</a>';
			print '</td>';
			
			for my $feature (@feature) {
			
				print "<td>";
				if ($hits{$token}{$feature}) {
				
					print chr(10003);
				}
				print "</td>";
			}
			
			print '</tr>';
			print "\n";
		}
		else {
		
			print "$freq\t$token";
			
			for my $feature (@feature) {
			
				print "\t";
				print "X" if $hits{$token}{$feature};
			}
			
			print "\n";
		}
	}
	
	if ($html) {
		print "</div></table>\n";
	}
}

sub select_list {
	
	my $target = shift;
	
	my $list;
	
	for my $name (@{Tesserae::get_textlist('grc', -sort=>1)}) {
	
		my $display = $name;
		$display =~ s/_/ /g;
		$display =~ s/\./—/;
		$display =~ s/\./ /g;
		$display =~ s/\b([a-z])/uc($1)/ge;
	
		my $selected = '';
		$selected = ' selected="selected"' if $name eq $target;
	
		$list .= "<option value=\"$name\"$selected>$display</option>\n";
	}
	
	my $html=<<END;
	
	<form action="$url{cgi}/syn-diagnostic-index.pl" target="left" method="post" id="Form1">

		<select name="target">
			<option value="*">Full Corpus</option>
			$list
		</select>
		
		<input type=\"submit\" value=\"Load\">
	</form>

END
	
	return $html;	
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
		
		my $sth = $dbh->prepare(
			'create table results (
				grc   varchar(40),
				freq  real,
				pos   char(5),
				la_1a varchar(22),
				la_1b varchar(22),
				la_2a varchar(22),
				la_2b varchar(22),
				la_3a varchar(22),
				la_3b varchar(22),				
				la_4a varchar(22),
				la_4b varchar(22),				
				v_1a  int,
				v_1b  int,
				v_2a  int,
				v_2b  int,
				v_3a  int,
				v_3b  int,
				v_4a  int,
				v_4b  int,
				p_1a  int,
				p_1b  int,				
				p_2a  int,
				p_2b  int,
				p_3a  int,
				p_3b  int,
				p_4a  int,
				p_4b  int,
				auth char(2)
			);'
		);
		
		$sth->execute;
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