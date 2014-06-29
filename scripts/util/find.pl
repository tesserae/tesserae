#!/usr/bin/env perl

=head1 NAME

find.pl - find features in a text

=head1 SYNOPSIS

find.pl [options] --stem STEM TEXTS

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--stem> STEM

Search for STEM.

=item B<--quiet>

Print usage and exit.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is find.pl.

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
use Encode;

# allow unicode output

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

# initialize some variables

my $help = 0;
my $quiet = 0;
my %feature = (stem => []);
my $unit = 'line';

# get user options

GetOptions(
	'stem=s' => \@{$feature{stem}},
	'help'  => \$help,
	'quiet' => \$quiet
);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

# get files to be processed from cmd line args

my @files = map { glob } @ARGV;
@files = @{Tesserae::process_file_list(\@files)};

# check each one

for my $name (@files) {
	
	print "$name:\n";

	my $lang = Tesserae::lang($name);

	my $file_base = catfile($fs{data}, 'v3', $lang, $name, $name);

	my $file_unit = "$file_base.$unit";
	my @unit = @{retrieve($file_unit)};
		
	my $file_token = "$file_base.token";
	my @token = @{retrieve($file_token)};

	my %hits;
	my $criteria;
	
	for my $featureset (qw/stem/) {
		
		my $file_index = "$file_base.index_$featureset";
		my %index = %{retrieve($file_index)};
							
		for my $feature (@{$feature{$featureset}}) {
			
			$criteria++;
		
			$feature = decode('utf8', $feature);
			$feature = Tesserae::standardize($lang, $feature);
		
			next unless defined $index{$feature};
			
			for my $token_id (@{$index{$feature}}) {
			
				my $unit_id = $token[$token_id]{uc($unit) . '_ID'};
				$hits{$unit_id}{$feature} ++;
			}
		}
	}
	
	my @results = sort {$a <=> $b} grep {scalar(keys %{$hits{$_}}) == $criteria} keys %hits;	
	@results = map {$unit[$_]{LOCUS}} @results;
	
	print join(", ", @results) . "\n";
	print "\n";
}