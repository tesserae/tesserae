#!/usr/bin/env perl

#
# corpus-stats.pl
#
# create lists of most frequent tokens by rank order
# in order to calculate stop words
# and frequency-based scores

=head1 NAME

corpus-stats.pl	- calculate corpus-wide statistics

=head1 SYNOPSIS

perl corpus-stats.pl [options] LANG [LANG2 [...]]

=head1 DESCRIPTION

Calculates corpus-wide frequencies for all features.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

I<add_column.pl> - add texts to the database

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is corpus-stats.pl.

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

use Storable qw(nstore retrieve);

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

#
# specify language to parse at cmd line
#

my @lang;

for (@ARGV) {

	$_ = lc($_);

	if (/^[a-z]{1,4}$/)	{ 
	
		next unless -d catdir($fs{data}, 'v3', $_);
		push @lang, $_;
	}
}

#
# main loop
#

# word counts come from documents already parsed.
# stem counts are based on word counts, but also 
# use the cached stem dictionary
#

for my $lang(@lang) {
	
	# get a list of all the word counts

	my @texts = @{Tesserae::get_textlist($lang, -no_part => 1)};
	
	#
	# combine the counts for each file to get a corpus count
	#

	my %total;
	my %count;

	for my $text (@texts) {
	
		print STDERR "checking $text:";
		
		for my $feature (qw/word stem syn 3gr/) {
		
			my $file_index = catfile($fs{data}, 'v3', $lang, $text, "$text.index_$feature");

			next unless -s $file_index;

			my %index = %{retrieve($file_index)};

			print STDERR " $feature";

			for (keys %index) { 
			
				$count{$feature}{$_} += scalar(@{$index{$_}});
				$total{$feature}     += scalar(@{$index{$_}});
			}
		}
		
		print STDERR "\n";
	}

	# after the whole corpus is tallied,	
	# convert counts to frequencies and save
	
	for my $feature (qw/word stem syn 3gr/) {
	
		next unless defined $count{$feature};

		my $file_freq = catfile($fs{data}, 'common', $lang . '.' . $feature . '.freq');

		print STDERR "writing $file_freq\n";

		open (FREQ, ">:utf8", $file_freq) or die "can't write $file_freq: $!";

		print FREQ "# count: $total{$feature}\n";
		
		for (sort {$count{$feature}{$b} <=> $count{$feature}{$a}} keys %{$count{$feature}}) {
		
			print FREQ "$_\t$count{$feature}{$_}\n";
		}

		close FREQ;
	}
}
