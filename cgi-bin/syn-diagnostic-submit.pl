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

name.pl	- do something

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
use DBI;
use Storable;
use utf8;
use Encode;

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# initialize some variables
my $target   = 'homer.iliad';
my @feature  = qw/trans1 trans2 trans2mws IBM/;
my $auth;
my $query;
my $pos;
my %param;
my $html     = 0;
my $help     = 0;

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
	
	print header('-charset'=>'utf-8', '-type'=>'text/html');

	$target     = $cgi->param('target')   || $target;
	$query      = $cgi->param('query');
	$auth       = $cgi->param('auth');
	$pos        = $cgi->param('pos');
	$feature[0] = $cgi->param('feature1') || $feature[0];
	$feature[1] = $cgi->param('feature2') || $feature[1];
	$feature[2] = $cgi->param('feature3') || $feature[2];
	$feature[3] = $cgi->param('feature4') || $feature[3];			

	for (qw/1a 1b 2a 2b 3a 3b 4a 4b/) {
	
		$param{"la_$_"} = $cgi->param("la_$_");
		$param{"v_$_"} = $cgi->param("v_$_");
	}

	$html = 1;
}

$query = Tesserae::standardize('grc', decode('utf8', $query));

my %freq = %{load_lex($target)};
my $freq = $freq{$query};

my $dbh = init_db();

print_head();

validate_input();

submit_rec();

print_foot();

#
# subroutines
#

#
# write record to database
#

sub submit_rec {

	my @head = ('query', 'freq', 'pos', sort(keys %param), 'auth');
	my @row = ($query, $freq, $pos, @param{sort keys %param}, $auth);

	my $sql = "insert into results values (" . join(",", map {/[^0-9\.]/ ? "\"$_\"" : $_} @row) . ");";

	# print "<div>$sql</div>\n";

	$dbh->do($sql);

	# print "<table>";
	# 
	# for (0..$#head) {
	# 
	# 	print "<tr><td>$head[$_]</td><td>$row[$_]</td></tr>";
	# }
	# 
	# print "</table>";
}

#
# check submission
#

sub validate_input {

	for my $val ($query, $freq, $auth) {
	
		unless (defined $val) {
			
			print "failed!";
			return 0;
		}
	}

	for (grep {/^v_/} keys %param) {
	
 		$param{$_} = ($param{$_} ? 1 : 0);
	}
	for (grep {/^la_/} keys %param) {
	
 		$param{$_} = 'NULL' unless defined $param{$_};
	}
	
	print "success!";
	
	return 1;
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
				p_1a  int,
				p_1b  int,				
				v_2a  int,
				v_2b  int,
				p_2a  int,
				p_2b  int,
				v_3a  int,
				v_3b  int,
				p_3a  int,
				p_3b  int,
				v_4a  int,
				v_4b  int,
				p_4a  int,
				p_4b  int,
				auth char(2)
			);'
		);
		
		$sth->execute;
	}

	return $dbh;
}


sub print_head {
	
	my $redirect = "$url{cgi}/syn-diagnostic.pl?target=$target;query=$query;feature1=$feature[0];feature2=$feature[1];feature3=$feature[2];feature4=$feature[3];auth=$auth";
	
	print <<END;
<html lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="author" content="Neil Coffee, Jean-Pierre Koenig, Shakthi Poornima, Chris Forstall, Roelant Ossewaarde">
		<meta name="keywords" content="intertext, text analysis, classics, university at buffalo, latin">
		<meta name="description" content="Intertext analyzer for Latin texts">
		<meta http-equiv="Refresh" content="0; url='$redirect'" />
		<link href="$url{css}/style.css" rel="stylesheet" type="text/css" />
		<link href="$url{image}/favicon.ico" rel="shortcut icon" />

		<title>Tesserae</title>

	</head>
	</head>
	<body>
		<div class="waiting">
		<p>
			Submitting...
END
}

sub print_foot {

	my $redirect = "$url{cgi}/syn-diagnostic.pl?target=$target;query=$query;feature1=$feature[0];feature2=$feature[1];feature3=$feature[2];feature4=$feature[3];auth=$auth";

	print <<END;
		</p>
		<p>
			<a href="$redirect" target="_top">return</a>
		</p>
	</body>
</html>
END
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
