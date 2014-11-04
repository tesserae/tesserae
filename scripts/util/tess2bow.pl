#!/usr/bin/env perl

=head1 NAME

tess2bow.pl - Print a Tesserae text as a simple bag of words.

=head1 SYNOPSIS

tess2bow.pl [options] NAME

=head1 DESCRIPTION

Prints out a Tesserae text in a simplified format. Useful if you want to process texts on your own and want to be sure you have the same "words" or other features as Tesserae uses.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<NAME>

The text to process.

=item B<--feature> FEAT

Each word token in the text will be translated into its FEAT feature(s). In the case where a token is indexed under multiple features, these will be separated by commas (but no spaces).

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is tess2bow.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris

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

# initialize some variables

my $help = 0;
my $feature = 'word';
my $unit = 'phrase';
my $show_id = 0;

# get user options

GetOptions(
	'help'  => \$help,
	'feature=s' => \$feature,
	'unit=s' => \$unit,
	'id' => \$show_id
);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# text to process

my $text = shift @ARGV;

my $base = Tesserae::get_base($text);
my $lang = Tesserae::lang($text);

unless (defined $base) {

	die "$text doesn't seem to be indexed."
}

# get Tesserae data

my @token = @{retrieve($base . ".token")};
my @unit = @{retrieve($base . ".$unit")};

#
# print out one unit at a time
#

for (my $unit_id = 0; $unit_id <= $#unit; $unit_id++) {

	my @line;
	
	for my $i (@{$unit[$unit_id]{TOKEN_ID}}) {
			
		next unless $token[$i]{TYPE} eq 'WORD';
		
		my $form = $token[$i]{FORM};
		
		if ($feature ne 'word') {
		
			$form = join(',', @{Tesserae::feat($lang, $feature, $form)})
		}
		
		push @line, $form;
	}
	
	print $unit_id . "\t" if $show_id;
	print join(" ", @line);
	print "\n";
}