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

use Storable;
use Data::Dumper;

# initialize some variables

my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

my $session = shift @ARGV;

my ($unit, $feature, $stop, $stbasis, $dist, $dibasis, $cutoff) = get_param($session);
my $index  = get_runs($session);
my $scores = get_scores($session);
my $comp   = comp_runs($index);
comp_scores($comp, $scores);


sub get_param {

	my $session = shift;
	
	my $file = catfile($session, 'runs.txt');
	
	open (my $fh, '<:utf8', $file) or die "Can't read $file: $!";
	
	<$fh>;
	
	my $line = <$fh>;
	
	chomp $line;
		
	my @field = split(/\t/, $line);
	
	close $fh;
	
	return @field[3..9];
}

sub get_runs {

	my $session = shift;
	
	my $file = catfile($session, 'runs.txt');
	
	open (my $fh, '<:utf8', $file) or die "Can't read $file: $!";
	
	<$fh>;
	
	my %index;
	my @runs;
	
	while (my $line = <$fh>) {
	
		chomp $line;
		
		my @field = split(/\t/, $line);
		
		my ($source, $target) = @field[1,2];
		
		for ($source, $target) {
		
			s/\.part\..*//;
		}
		
		push @{$index{$source}{$target}}, $field[0];
	}
	
	close $fh;
	
	return (\%index);
}

sub get_scores {

	my $session = shift;
	
	my $file = catfile($session, 'scores.txt');
	
	open (my $fh, '<:utf8', $file) or die "Can't read $file: $!";
	
	<$fh>;
	
	my @scores;
		
	while (my $line = <$fh>) {
	
		chomp $line;
		
		my @field = split(/\t/, $line);
		
		$scores[$field[0]][$field[1]] = $field[2];
	}
	
	close $fh;
	
	return \@scores;
}

sub comp_runs {

	my $ref   = shift;
	my %index = %$ref;

	my @source = sort (keys %index);
	my @target = sort (keys %{$index{$source[0]}});
	
	my @comp;
	
	print join("\t", qw/run_id	source	target	unit	feature	stop	stbasis	dist	dibasis	cutoff	words	lines	phrases	lemmata/) . "\n";

	for my $source (@source) {

		for my $target (@target) {
			
			my $base_s = catfile($fs{data}, 'v3', 'la', $source, $source);
			my $base_t = catfile($fs{data}, 'v3', 'la', $target, $target);
			
			my $tokens_s  = scalar(@{retrieve("$base_s.token")});
			my $tokens_t  = scalar(@{retrieve("$base_t.token")});
			my $lines_s   = scalar(@{retrieve("$base_s.line")});
			my $lines_t   = scalar(@{retrieve("$base_t.line")});
			my $phrases_s = scalar(@{retrieve("$base_s.phrase")});
			my $phrases_t = scalar(@{retrieve("$base_t.phrase")});
			
			my %combined;
			
			for my $base ($base_s, $base_t) {
			
				my %index = %{retrieve($base . ".index_stem")};
			
				for (keys %index) {
			
					$combined{$_} = 1;
				}
			}
			
			print join("\t", 
				"c" . scalar(@comp),
				$source,
				$target,
				$unit,
				$feature,
				$stop,
				$stbasis,
				$dist,
				$dibasis,
				$cutoff,
				($tokens_s  * $tokens_t),
				($lines_s   * $lines_t), 
				($phrases_s * $phrases_t), 
				scalar(keys %combined)
			) . "\n";

			push @comp, $index{$source}{$target};
		}
	}
	
	return \@comp;
}

sub comp_scores {

	my ($ref_comp, $ref_scores) = @_;
	my @comp   = @$ref_comp;
	my @scores = @$ref_scores;
	
	print join("\t", qw/run_id score count/) . "\n";
	
	for my $c (0..$#comp) {
		
		my %tally;
		
		for my $run_id (@{$comp[$c]}) {
		
			for my $score (0..$#{$scores[$run_id]}) {
			
				$tally{$score} += $scores[$run_id][$score];
			}
		}
		
		for my $score (sort {$a <=> $b} keys %tally) {
		
			print join("\t", 'c' . $c, $score, $tally{$score}) . "\n";
		}
	}
}