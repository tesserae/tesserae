#! /usr/bin/perl

# clean.pl
#
# delete existing data

=head1 NAME

clean.pl - delete existing data

=head1 SYNOPSIS

perl clean.pl [options] [LANG [LANG2 [...]]

=head1 DESCRIPTION

Deletes some or all elements of the internal database used by Tesserae.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<LANG>

Language code(s) to clean.  If none specified, apply to all languages.

=item B<--texts>

Clean texts database.  Deletes all feature indices for all installed texts.

=item B<--dictionaries>

Clean cached stem and synonym dictionaries.

=back

=head1 KNOWN BUGS

Haven't tested this script in a while.  Could have some unexpected results at this point.

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is clean.pl.

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

# variables set from config

my %fs;
my %url;
my $lib;

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $config;
	my $pointer;
			
	while (1) {

		$config  = catfile($lib, 'tesserae.conf');
		$pointer = catfile($lib, '.tesserae.conf');
	
		if (-s $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$config = <FH>;
			
			chomp $config;
			
			last;
		}
		
		last if (-s $config);
							
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			
			next;
		}
		
		die "can't find tesserae.conf!\n";
	}
	
	# read configuration		
	my %par;
	
	open (FH, $config) or die "can't open $config: $!";
	
	while (my $line = <FH>) {
	
		chomp $line;
	
		$line =~ s/#.*//;
		
		next unless $line =~ /(\S+)\s*=\s*(\S+)/;
		
		my ($name, $value) = ($1, $2);
			
		$par{$name} = $value;
	}
	
	close FH;
	
	# extract fs and url paths
		
	for my $p (keys %par) {

		if    ($p =~ /^fs_(\S+)/)		{ $fs{$1}  = $par{$p} }
		elsif ($p =~ /^url_(\S+)/)		{ $url{$1} = $par{$p} }
	}
}

# load Tesserae-specific modules

use lib $fs{script};

use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use File::Path qw(mkpath rmtree);
use File::Basename;
use Storable qw(nstore retrieve);

# user options

my $help = 0;
my $quiet = 0;

my %clean = (
	text => 0,
	dict => 0
			 );
			
GetOptions( 
	"text"  => \$clean{text}, 
	"dict"  => \$clean{dict},
	"quiet" => \$quiet,
	"help"  => \$help );

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

# specify languages to clean as arguments

my @lang = @ARGV;

# if none specified, clean all

unless (@lang) {

	opendir (DH, catdir($fs{data}, 'v3'));
	
	@lang = grep {/^[^.]/ && -d catdir($fs{data}, 'v3', $_) } readdir DH;
	
	closedir DH;
}

# these will be modified to remove deleted texts

my %abbr = %{ retrieve(catfile($fs_data, 'common', 'abbr')) };
my %lang = %{ retrieve(catfile($fs_data, 'common', 'lang')) };

# clear preprocessed texts from the database

if ($clean{text}) {
	
	for (@lang) { 
	
		rmtree catdir($fs{data}, 'v3', $_);
		mkpath catdir($fs{data}, 'v3', $_);

		unlink glob(catfile($fs{data}, 'common', $_ . '.*.count'));
		unlink glob(catfile($fs{data}, 'common', $_ . '.*.freq'));
	}
	
	for my $text (keys %abbr) {
	
		if (grep {/$lang{$text}/} @lang) {
		
			delete $abbr{$text};
			delete $lang{$text};
		}
	}
}

# save changes

nstore \%abbr, catfile($fs{data}, 'common', 'abbr');
nstore \%lang, catfile($fs{data}, 'common', 'lang');

# remove dictionaries

if ($clean{dict}) {

	for (@lang) {

		unlink glob(catfile($fs{data}, 'common', $_ . '.*.cache'));
	}
}
