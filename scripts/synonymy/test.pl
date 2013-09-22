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
use Unicode::Normalize;
use utf8;

# initialize some variables

my $help = 0;

my $re_dia   = qr/[\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]/;
my $re_vowel = qr/[αειηουωΑΕΙΗΟΥΩ]/;

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

binmode STDOUT, ':utf8';

my $file = shift @ARGV;

$file = 'homer.iliad' unless defined $file;

#
#
#

my $file_stem  = catfile($fs{data}, 'common', 'grc.stem.cache');
my $file_trans = catfile($fs{data}, 'common', "grc.trans.cache");

my %stem = %{retrieve($file_stem)};
my %trans = %{retrieve($file_trans)};

my $lang = Tesserae::lang($file);

my $file_base = catfile($fs{data}, 'v3', $lang, $file, $file);

my $file_index_word  = $file_base . ".index_word";
my $file_index_stem  = $file_base . ".index_stem";

my %index_word = %{retrieve($file_index_word)};
my %index_stem = %{retrieve($file_index_stem)};
my %index_trans;



print "translation dictionary has " . scalar(keys %trans) . " entries\n";
print "$file has " . scalar(keys %index_word) . " words\n";
print "$file has " . scalar(keys %index_stem) . " stems\n";

my %count;

for my $stem (keys %index_stem) {
	
	my $stem_clean = NFKD($stem);
	$stem_clean =~ s/\d//g;
	$stem_clean =~ s/^(${re_dia}+)(${re_vowel}{2,})/$2/;
	$stem_clean =~ s/^(${re_dia}+)(${re_vowel}{1})/$2$1/;
	$stem_clean =~ s/σ\b/ς/;
	
	if (defined $trans{$stem_clean}) {
		push @{$count{yes}}, $stem_clean;
	}
	else {
		push @{$count{no}}, $stem_clean;
	}
}

print "Found:\n";

for (keys %count) {

	print join("\t", $_, scalar(@{$count{$_}})) . "\n";
}

print STDERR "writing not_found.txt\n";

my $pr = ProgressBar->new(scalar @{$count{no}});

open(FH, ">:utf8", "not_found.txt");

for (sort @{$count{no}}) {

	$pr->advance();

	print FH "$_\n";
}

close FH;

print STDERR "writing dict.txt\n";

$pr = ProgressBar->new(scalar keys %trans);

open(FH, ">:utf8", "dict.txt");

for (sort keys %trans) {

	$pr->advance;
	print FH "$_\n";
}

close FH;

sub stems {

	my $form = shift;
	
	my @stems;
	
	if (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}

sub syns {
	
	my $stem = shift;
	
	my @syns;
	
	if (defined $trans{$stem}) {

		@syns = @{$trans{$stem}};
	}
	else {
	
		@syns = ($stem);
	}
	
	return Tesserae::uniq(\@syns);
}
