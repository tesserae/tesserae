#!/usr/bin/env perl

=head1 NAME

batch.dl.pl - download results produced by batch.run.pl

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.dl.pl.

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
use Archive::Zip;
use DBI;

# initialize some variables

my $help;
my $session;
my @dl;

my $dir_client = catdir($fs{tmp},  'batch');
my $dir_manage = catdir($fs{data}, 'batch');

#
# is this script being called from the web or cli?
#

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# get user options
#

# from command line

if ($no_cgi) {

	GetOptions(
		'session=s' => \$session,
		'dl=s'      => \@dl,
		'help'      => \$help
	);

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}

	unless ($session) { pod2usage(1) }
}
	
# from web interface
	
else {

	$session  = $query->param('session');
	@dl       = $query->param('dl');
	
	unless ($session) {
		
		die "no session specified from web interface";
	}
}

# establish session directory

my $dir_session = catdir($fs{data}, 'batch', 'batch.' . $session);

# check files requested

my @files = validate(\@dl);

unless (@files) { quit_no_files() }

# output file: if more than one file requested, create a zip archive

my $dl_file = $#files > 0 ? $session . '.zip'
                          : $session . '.' . $files[0];

# html header

print header(
	-type       => 'application/octet-stream', 
	-attachment => $dl_file
);

if ($#files > 0) {

	# create zip

	my $zip = create_archive(@files);

	# send it to user

	$zip->writeToFileHandle(*STDOUT);
}
else {
	
	export_files($files[0]);
}

#
# subroutines
#

# make sure requested session, files exist

sub validate {

	my ($ref) = @_;
	
	my @dl = @$ref;

	my $flag = 0;

	# make sure session exists

	unless (-d $dir_session) {
	
		warn "non-existent session $session";
		$flag = 1;
	}
	
	# make sure search is complete
	
	my $db_manage = catfile($fs{data}, 'batch', 'queue.db');
	my $dbh_manage = DBI->connect("dbi:SQLite:dbname=$db_manage", "", "");
	
	my $status = $dbh_manage->selectrow_arrayref(
		
		"select STATUS from queue where SESSION='$session';"
	);
	
	unless (defined($status) and $status->[0]==1) {
	
		$flag = 1;
	}
		
	# return empty list if one of the previous tests failed
	
	if ($flag) {
	
		return ();
	}
	
	# otherwise, check the requested files against results
	
	opendir (my $dh, $dir_session) or die "can't read $dir_session: $!";
	
	my @all_files = grep { /^[^\.]/ } readdir ($dh);
	
	closedir ($dh);
		
	@dl = @{Tesserae::intersection(\@dl, \@all_files)};
					
	return @dl;
}

#
# build zip file
#

sub create_archive {

	my @files = @_;
	
	my $zip = Archive::Zip->new();
	
	for my $file (@files) {
	
		my $orig_file = catfile($dir_session, $file);
		my $arch_file = $file;
	
		print STDERR "$orig_file -> $arch_file\n";
	
		my $member = $zip->addFile($orig_file, $arch_file);
		
		print STDERR "member: $member\n";
	}
	
	return $zip;
}

#
# export database
#

sub export_files {

	my $name     = shift;
	my $file_in  = catfile($dir_session, $name);
	
	open(my $fh_in,  '<', $file_in) 
		or die "can't read $file_in: $!";
		
	binmode($fh_in);
	binmode(STDOUT);
	
	my $buffer;
	
	while (read($fh_in, $buffer, 4096)) {
	
		print $buffer;
	}
}

#
# error message
#

sub quit_no_files {

	print header;
	
	print <<END;
<html>
	<head>
	<title>Tesserae</title>
	</head>
	<body>
		<p>
			Can't find the file(s) you tried to download. Please try again.
		</p>
	</body>
</html>
END

	exit;
}
