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

lsa.samples.pl - create training set for lsa

=head1 SYNOPSIS

lsa.samples.pl [options] FILES

=head1 DESCRIPTION

Breaks each text up into series of roughly equally-sized samples to use as input 
data for the LSA search tool.  Two series of samples are created from each text: 
a larger one, used for training, and a smaller one, from which queries are drawn.

Training is done on the source set using I<lsa.train.py>.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<FILES>

The list of files to index.

=item B<--large> I<SIZE>

Create 'large' samples (training set) using approximately I<SIZE> characters of the 
original text for each sample. Default is 1000.

=item B<--small> I<SIZE>

Create 'small' samples (query set) using approximately I<SIZE> characters of the 
original text for each sample. Default is 500.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is lsa.samples.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall, Walter Scheirer

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

use Storable qw(nstore retrieve);
use File::Basename;
use File::Path qw(mkpath rmtree);

# approximate size of samples in characters

my %size = (large => 1000, small => 500);
my $help;

# check for cmd line options

GetOptions(
	'large=i' => \$size{large},
	'small=i' => \$size{small},
	'help'    => \$help
	);

# print usage if the user needs help
	
if ($help) {

	pod2usage(1);
}

# global variables hold working data

my $lang;
my @token;
my @phrase;

# get texts to process from command-line args

my @files = map { glob } @ARGV;

my @names = @{Tesserae::process_file_list(\@files)};

# process each text in turn

for my $name (@names) {
	
	# set language
	
	$lang = Tesserae::lang($name);
		
	# load text from v3 database
	
	my $base = catfile($fs{data}, 'v3', $lang, $name, $name);

	@token = @{retrieve("$base.token")};
	@phrase = @{retrieve("$base.phrase")}; 
	
	#
	# process each file as both target and source
	#
	
	print STDERR "$name\n";
	
	for my $mode (qw/small large/) {

		print STDERR "$mode:\n";

		my @bounds;
	
		# create/clean output directory

		my $opdir = catfile($fs{data}, 'lsa', $lang, $name, $mode);
		
		rmtree($opdir);
		mkpath($opdir);
						
		# write samples
				
		my $pr = ProgressBar->new(scalar(@phrase));
		
		my $ndigit = length($#phrase);
		
		for my $i (0..$#phrase) {
		
			$pr->advance();
			
			my $opfile = catfile($opdir, sprintf("%0${ndigit}i", $i));
			
			open (FH, ">:utf8", $opfile) || die "can't create $opfile: $!";
			
			my ($sample, $lbound, $rbound) = sample($size{$mode}, $i);
			
			print FH $sample;
			push @bounds, [$lbound, $rbound];
			
			close FH;
		}
		
		my $file_bounds = catfile($fs{data}, 'lsa', $lang, $name, "bounds.$mode");
		
		nstore \@bounds, $file_bounds;
	}
}

#
# subroutines
#

sub sample {

	my ($smin, $unit_id) = @_;
		
	my @tokens;
	my $size = 0;
	
	for (@{$phrase[$unit_id]{TOKEN_ID}}) {
	
		if ($token[$_]{TYPE} eq "WORD") {
		
			push @tokens, $_;
			$size += length($token[$_]{FORM});
		}
	}
	
	my $lpos = $phrase[$unit_id]{TOKEN_ID}[0];
	my $rpos = $phrase[$unit_id]{TOKEN_ID}[-1];
	
	while (($size < $smin) and ($rpos-$lpos < $#token)) {
		
		ADDL:
		while ($lpos > 0) {
		
			$lpos --;
			
			next ADDL unless $token[$lpos]{TYPE} eq "WORD";
			
			push @tokens, $lpos;
			
			$size += length($token[$lpos]{FORM});
			
			last ADDL;
		}
		
		ADDR:
		while ($rpos < $#token) {
		
			$rpos ++;
			
			next ADDR unless $token[$rpos]{TYPE} eq "WORD";
			
			push @tokens, $rpos;
			
			$size += length($token[$rpos]{FORM});
			
			last ADDR;
		}
	}
	
	my @stems;
	
	for (@tokens) {
	
		push @stems, @{Tesserae::feat($lang, 'stem', $token[$_]{FORM})};
	}
		
	my $sample = join(" ", @stems)  . "\n";
		
	return ($sample, $lpos, $rpos);
}

