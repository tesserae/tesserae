#!/usr/bin/env perl

=head1 NAME

bigram_freq.pl - calculate bigram counts from multitext index

=head1 SYNOPSIS

bigram_freq.pl [options]

=head1 DESCRIPTION

Calculates bigram counts for all texts in the corpus based on the multi-text indices.
Note: index_multi.pl must have been run first.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang LANG>

Language to index. Default is "la."

=item B<--parallel N>

Allow up to N processes to run in parallel.  Requires Parallel::ForkManager.

=item B<--quiet>

Don't print messages to STDERR.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is bigram_freq.pl.

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

use Storable;

# optional modules

my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

# initialize some variables

my $help = 0;
my $quiet = 0;
my $max_processes = 0;
my $lang = 'la';
my @feat = qw/word stem/;
my @corpus = @{Tesserae::get_textlist($lang, -no_part => 1)};
@corpus = grep { ! /vulgate/ } @corpus;

#
# command-line options
#

GetOptions(
	'lang=s'          => \$lang,
	'parallel=i'      => \$max_processes,
	'quiet'           => \$quiet,
	'help'            => \$help
);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

print STDERR "indexing " . scalar(@corpus) . " texts...\n";

# initialize process manager

my $prmanager;

if ($max_processes) {

	$prmanager = Parallel::ForkManager->new($max_processes);
}

for my $text (@corpus) {

	# fork
	
	if ($max_processes) {
	
		$prmanager->start and next;
	}

	for my $unit (qw/phrase line/) {

		print STDERR "unit: $unit\ntext: $text\n";

		if ($unit eq 'line' and Tesserae::check_prose_list($text)) {

			next;
		}
	
		my $file_unit = catfile($fs{data}, 'v3', $lang, $text, $text . ".$unit");
		my $unit_count = scalar(@{retrieve($file_unit)});
		
		for my $feature (@feat) {
	
			my $file_index = catfile($fs{data}, 'v3', $lang, $text, $text . '.multi_' . $unit . '_' . $feature);
			my %index = %{retrieve($file_index)};
	
			my %count_this;
						
			for my $bigram (keys %index) {
			
				$count_this{$bigram} = scalar(keys %{$index{$bigram}});
			}
			
			my $file_count = catfile($fs{data}, 'v3', $lang, $text, $text . '.freq_bigram_' . $unit . '_' . $feature);

			open (my $fh, '>:utf8', $file_count) or die "Can't write $file_count: $!";
			print $fh "# count: $unit_count\n";
		
			for my $bigram (sort {$count_this{$b} <=> $count_this{$a}} keys %count_this) {
		
				print $fh "$bigram\t$count_this{$bigram}\n";
			}
		
			close $fh;

		}		
	}
	
	$prmanager->finish if $max_processes;
}

$prmanager->wait_all_children if $max_processes;

