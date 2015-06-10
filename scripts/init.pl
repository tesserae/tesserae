#!/usr/bin/env perl

=head1 init.pl

init.pl - run scripts to set up Tesserae database

=head1 SYNOPSIS

init.pl [options]

=head1 DESCRIPTION

This just runs a bunch of other Tesserae scripts that set up the
feature dictionaries, add all the texts to the database, and build
the dropdown menus for the (optional) web interface. You could do
these things individually if you want to customize your install;
this script is just provided to make "default" case setup easier.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--lang> LANG [--lang LANG2 ...]

Languages to set up initially. Tesserae expects LANG to correspond
to a subdirectory of I<texts/>, containing all the works in that
language. The version of Tesserae on GitHub has a large number of
texts in Greek (I<texts/grc>) and Latin (I<texts/la>), mostly from 
Perseus, as well as a couple of experimental texts in English 
(I<texts/en>), of diverse provenance. You can use the flag more
than once to select multiple languages. The default setting is 
B<--lang> la B<--lang> grc; i.e., if you don't specify a language
at all you'll get both Greek and Latin by default. If your machine
is slow and you don't care about, say, Greek, it's smart to use 
the flag to specify only one language. See "Known Bugs" below if
you're using English.

=item B<--feature> FEAT [--feature FEAT2]

The feature sets to install, in addition to exact word matching.
Defaults to 'stem'. You probably don't want to mess around with 
this; but see "Known Bugs" regarding English stem matching.

=item B<--clean>

Use scripts/v3/clean.pl to delete existing texts and feature
dictionaries before installing texts. This will run clean.pl
with the flags --text --dict LANG [LANG2 ...], for each of the
languages specified using the B<--lang> option or for 'la' and 
'grc' by default (see above).

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

English stem matching won't work out of the box, since there's no
dictionary. You have to index for English stems separately, using
Lingua::Stem, by running add_col_stem.pl with the --use-lingua flag.
So if you run this script with the option '--lang en', turn off stem
indexing by specifying '--feat ""' (i.e. nothing inside double-quotes) 
or things might go poorly. Or just install the English texts yourself
later.

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is install.pl.

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


# initialize some variables

my $help = 0;
my $clean = 0;
my @inst_lang;
my @inst_feature;


# get user options

GetOptions(
	'lang=s'    => \@inst_lang,
	'feature=s' => \@inst_feature,
	'clean'     => \$clean,
	'help'      => \$help
);

# apply defaults if user didn't set any options

@inst_lang    = qw/la grc/   unless @inst_lang;
@inst_feature = qw/stem 3gr/ unless @inst_feature;

@inst_feature = grep {/\S/} @inst_feature;

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

#
# build dictionaries
#

print STDERR "building dictionaries\n";

do_cmd("perl " . catfile($fs{script}, 'build-stem-cache.pl '. join(" ", @inst_lang)));
do_cmd("perl " . catfile($fs{script}, 'patch-stem-cache.pl'));

print STDERR "done\n\n";

#
# add texts
#

print STDERR "adding texts\n";

for my $lang (@inst_lang) {

	my $script = catfile($fs{script}, 'v3', 'add_column.pl');
	my $texts  = catfile($fs{text}, $lang, '*');
	
	do_cmd("perl $script $texts");

	for my $feature (@inst_feature) {
		
		$script = catfile($fs{script}, 'v3', "add_col_stem.pl --feat $feature");
	
		do_cmd("perl $script $texts");
	}
}

print STDERR "done\n\n";

#
# calculate corpus stats
#
{
	print "calculating corpus-wide frequencies\n";
	
	my $script = catfile($fs{script}, 'v3', 'corpus-stats.pl');
	
	my $features = join(" ", map {"--feat $_"} @inst_feature);
	
	my $langs = join(" ", @inst_lang);
	
	do_cmd("perl $script $features $langs");
	
	print STDERR "done\n\n";
}

#
# create drop-down lists
#

{

	my $script = catfile($fs{script}, 'textlist.pl');
	my $langs = join(" ", @inst_lang);

	do_cmd("perl $script $langs");
}

#
# subroutines
#

sub do_cmd {

	my $command = shift;
	
	print STDERR "$command\n";
	
	print STDERR `$command`;
	
	return;
}

