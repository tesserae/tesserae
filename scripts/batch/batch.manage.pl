#!/usr/bin/env perl

=head1 NAME

batch.manage.pl - manage the batch job queue

=head1 SYNOPSIS

batch.manage.pl [options]

Meant to be run periodically by cron.

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.manage.pl.

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


# initialize some variables

my $queue = catdir($fs{tmp}, 'tesbatch.queue');

my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# get the next queued session

my $session = get_next() or exit;

# remove it from the queue

dequeue($session);

# run the session

run_session($session);

#
# subroutines
#

#
# check the queue
#

sub get_next {
	
	opendir(my $dh, $queue) || die "can't open queue $queue: $!";
	
	my @session = sort(grep { /^\d{8}$/ } readdir($dh));
	
	closedir($dh);
	
	return $session[0];
}

#
# remove a session from the queue
#

sub dequeue {

	my $session = shift;
	
	my $file_session = catfile($queue, $session);
		
	my $success = unlink($file_session);
	
	unless ($success) {
	
		warn "can't remove $session from queue: $!";
	}
	
	return $success;
}

#
# start session
#

sub run_session {
	
	my $session = shift;
	
	my $file_session = catfile($fs{tmp}, 'tesbatch.' . $session);
	
	my $file_script = catfile($fs{script}, 'batch', 'batch.run.pl');
	
	my $cmd = join(" ",
		$file_script,
		'--quiet',
		'--manage',
		'--plugin' => 'Tallies',
		$file_session
	);
	
	`$cmd`;
}