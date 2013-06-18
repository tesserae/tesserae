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

# initialize some variables

my $help;
my $session;
my @dl;

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

# html header

print header(-type => 'application/zip', -attachment => $session . '.zip');

# check files requested

my @files = validate($session, \@dl);

# create zip

my $zip = create_archive(@files);

# send it to user

$zip->writeToFileHandle(*STDOUT, 0);

#
# subroutines
#

# make sure requested session, files exist

sub validate {

	my ($session, $ref) = @_;
	
	my @dl = @$ref;

	my $flag = 0;

	# make sure session exists
	
	my $dir_session = catdir($fs{tmp}, 'tesbatch.' . $session);

	unless (-d $dir_session) {
	
		warn "non-existent session $session";
		$flag = 1;
	}
	
	# make sure search is complete
	
	my $file_status = catfile($fs{tmp}, 'tesbatch.' . $session, '.status');
	
	if (-e $file_status) {
		
		open(my $fh_status, '<', $file_status) or die "can't read $file_status: $!";
		
		my $line = <$fh_status>;
		
		my ($time_now, $count_now, $status) = split(/\t/, $line);
		
		unless ($status == 1) {
		
			warn "session $session is not complete";
			$flag = 1;
		}
	}
	else {
	
		warn "session $session has not been processed";
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
	
	my $dir_session = catdir($fs{tmp}, 'tesbatch.' . $session);
	
	for my $file (@files) {
	
		$zip->addFile( catfile($dir_session, $file), $file);
	}
	
	return $zip;
}
