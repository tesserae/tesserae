#!/usr/bin/env perl

#
# batch.prepare.pl - prepare a systematic set of tesserae searches
#
#   for Neil Bernstein

=head1 NAME

batch.prepare.pl - prepare a systematic set of tesserae searches

=head1 SYNOPSIS

batch.prepare.pl [options] [tessoptions]

=head1 DESCRIPTION

This script accepts Tesserae search parameters specifying multiple values per parameter.
It then generates every combination of these parameters and writes to a file a list
of individual Tesserae searches to be performed. The idea is that you would then feed 
this list into batch.run.pl, which would run the searches, although if you really wanted 
to you could also run the output file as a shell script.

The simplest way to use this script is to specify Tesserae search options just as for
read_table.pl; Here, unlike with read_table.pl, you can specify multiple values. 

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--outfile> I<FILE>

The destination for output.

=item B<--interactive>

This flag initiates "interactive" mode.  The script will ask you what values or ranges 
you want for each of the available parameters.

=item B<--infile> I<FILE>

This will attempt to read parameters from FILE.  Use '--man' to read about the format 
of this file.

=item B<--quiet>

Less output to STDERR.

=item B<--help>

Print usage and exit.

=item B<--man>

Display detailed help.

=back

=head1 TESSERAE SEARCH OPTIONS

Aside from parsing out lists and ranges, the script simply passes these on to Tesserae's
read_table.pl.

=over

=item B<--source> I<SOURCE>

the source text

=item B<--target> I<TARGET>

the target text

=item B<--unit> I<UNIT>

unit to search: "line" or "phrase"

=item B<--feature> I<FEAT>

feature to search on: "word", "stem", "syn", or "3gr"

=item B<--stop> I<N>

number of stop words

=item B<--stbasis> I<STBASIS>

stoplist basis: "corpus", "source", "target", or "both"

=item B<--dist> I<D>

max distance (in words) between matching words

=item B<--dibasis> I<DIBASIS>

metric used to calculate distance: "freq", "freq-target", "freq-source", "span", 
"span-target", or "span-source"

=back

=head1 SPECIFYING MULTIPLE VALUES

This can be done in a couple of ways.  First, you can separate different values with commas.
When entering options at the command-line, no whitespace is allowed, but using an input 
file or interactive mode whitespace is allowed.  Second, for names of texts only, 
you can use the wildcard character '*' to match several names at once.  Third, for 
numeric parameters only, you can specify a range by giving the start and end values 
separated by a dash (but no space); optionally, you can append a "step" value, separated 
from the range by a colon (but no space), e.g. '1-10' or '10-20:2'. The default step is 1.

=head2 EXAMPLE

  batch.prepare.pl --outfile my.list.txt                          \
                   --target  lucan.bellum_civile,statius.thebaid  \
                   --source  vergil.aeneid.part.*                 \
                   --stop    5-10                                 \
                   --dist    4-20:4

=head1 INPUT FILE FORMAT

It may be easier to lay out the various options in a separate file, from which
batch.prepare.pl can read using the I<--infile> flag.  

The file should be arranged as follows.  Values for a given search parameter should be 
grouped together, one per line, under a header in square brackets giving the name of the 
parameter. Text names can use the wildcard as above.  Numeric ranges can be specified as 
above, and in this case whitespace around the "-" or ":" chars is okay.  Alternately, 
you can specify a range verbosely using one of the forms

	range(from=I; to=J)

or

	range(from=I; to=J; step=K)

where I, J, and K are integers.

=head2 SAMPLE INPUT FILE

  # my batch file
  # -- comments beginning with a hash sign are ignored

  [source]
  vergil.aeneid.part.*          # wildcard
	
  [target]
  lucan.bellum_civile.part.*    # multiple values on separate lines
  statius.thebaid.part.*
  silius_italicus.punica.part.*

  [stop]
  10 - 20 : 5                   # range can have spaces

  [stbasis]
  both                          # single values work too
	
  [dist]
  range(from=8; to=16; step=4)  # verbose-style range

=head1 KNOWN BUGS

None, but nothing has really been tested much.

=head1 SEE ALSO

batch.run.pl

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.prepare.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall, Neil Bernstein, Xia Lu

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut


use strict;
use warnings;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

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

use DBI;
use File::Path qw/mkpath rmtree/;
use Pod::Usage;
use Term::UI;
use Term::ReadLine;

#
# initialize variables
#

my $lang = 'la';

my @params = qw/
	source
	target
	unit
	feature
	stop
	stbasis
	dist
	dibasis/;

my $interactive = 0;
my $quiet       = 0;
my $file_output;
my $help;
my $man;

my %par;

#
# get user options
#
	
# define options for all params

my %opt;

for (@params) { 

	$par{$_} = undef;
	$opt{"$_=s"} = \$par{$_};
}

# get input from cmd line args

GetOptions(%opt,
	'help'        => \$help,
	'interactive' => \$interactive,
	'outfile=s'   => \$file_output
);

# print brief/detailed help if requested

if ($help) { 
	
	pod2usage(-verbose => 1);
}
elsif ($man) {
	
	pod2usage(-verbose => 2);
}

# or enter interactive mode if requested

elsif ($interactive) {
	
	interactive()
}

# print usage and exit if source or target is missing

unless ($par{source} and $par{target}) {

	print STDERR "Source or target unspecified.\n";
	pod2usage(-verbose => 0);
}

# parse user input for ranges, lists

%par = %{parse_params(\%par)};

#
# create config file
#

write_config($file_output, \%par);

#
# subroutines
#

#
# parse command-line options 
# for multiple values, ranges
#

sub parse_params {
	
	my $ref = shift;
	my %par = %$ref;

	for (@params) {

		next unless defined $par{$_};
		
		my @val;
		my @working = $par{$_};
			
		if ($par{$_} =~ /,/) {
	
			@working = split(/,/, $par{$_});
		}
		
		for (@working) {
			
			s/\s//g;

			if (/range\(from\D*(\d+)\b.*?to\D*(\d+)(.*)/) {

				my ($from, $to, $tail) = ($1, $2, $3);

				my $step = 1;

				if (defined $tail and $tail =~ /step\D*(\d+)/) {

					$step = $1;
				}

				push @val, "$from-$to:$step";
			}
			elsif (/(\d+)\s*-\s*(\d+)(.*)/) {

				my ($from, $to, $tail) = ($1, $2, $3);

				my $step = 1;

				if (defined $tail and $tail =~ /:\s*(\d+)/) {

					$step = $1;
				}

				push @val, "$from-$to:$step";
			}
			else {
				push @val, $_;
			}
		}

		$par{$_} = \@val;
	}
	
	# expand text names for source, target
		
	for (qw/source target/) {
		
		next unless defined $par{$_};
	
		my @list;
		my @all = @{Tesserae::get_textlist($lang, -sort=>1)};

		for my $spec (@{$par{$_}}) {
		
			$spec =~ s/\./\\./g;
			$spec =~ s/\*/.*/g;
			$spec = "^$spec\$";
			
			push @list, (grep { /$spec/ } @all);
		}
				
		$par{$_} = \@list;
	}
	
	return \%par;
}

#
# prompt for options interactively
#

sub interactive {

	#
	# custom help for each parameter
	#
	
	my $all_texts = Tesserae::get_textlist($lang, -sort=>1);
	
	for (@$all_texts) {
	
		if (/\.part\./) {
		
			$_ = "  " . $_;
		}
	}
	
	my %help = (
		source	=> 
			"Source means the older, alluded-to text.\n"
			. "You may enter a single text or a comma-separated list; "
			. "you can also match multiple texts by using the wildcard '*'.\n"
			. "\n"
			. "For example:\n"
			. "   vergil.aeneid.part.*\n"
			. "will match all books of the Aeneid.\n"
			. "\n"
			. "Type 'choices' to see a list of all texts in the corpus\n",
			
		target =>
			"Target means the more recent, alluding text.\n"
			. "You may enter a single text or a comma-separated list; "
			. "you can also match multiple texts by using the wildcard '*'.\n"
			. "\n"
			. "For example:\n"
			. "   vergil.aeneid.part.*\n"
			. "will match all books of the Aeneid.\n"
			. "\n"
			. "Type 'choices' to see a list of all texts in the corpus\n",
			
		unit =>
			"Unit means the chunk of text used as the unit of matching.\n"
			. "Select one or more options, separated by commas:\n"
			. "  'line'   means search on verse line;\n"
			. "  'phrase' means search on grammatical phrases, determined\n"
			. "           by editorial punctuation marks.\n"
			. "NB: If either work is prose, 'line' returns the same results as 'phrase'.\n",
			
		feature =>
			"Feature means the textual characteristic on which similarity is judged.\n"
			. "Select one or more options, separated by commas:\n"
			. "  'word' will only return exact-word matches;\n"
			. "  'stem' will match differently-inflected forms of the same headword;\n"
			. "  'syn'  will attempt to match words having related meanings (v. buggy);\n"
			. "  '3gr'  will match on common three-letter substrings\n",
			
		stop =>
			"Stoplist size means the number of high-frequency words to exclude.\n"
			. "Enter one or more integers, separated by commas; " 
			. "you may also specify a range using the form 'start - end [: step]'\n"
			. "\n"
			. "For example:\n"
			. "   1 - 10          is equivalent to 1,2,3,4,5,6,7,8,9,10\n"
			. "  16 - 24 : 2      is equivalent to 16,18,20,22,24\n",
			
		stbasis =>
			"Stoplist basis means the method for calculating high-frequency words.\n"
			. "Select one or more options, separated by commas:\n"
			. "  'target' takes the most frequent words in the target text;\n"
			. "  'source' takes the most frequent words in the source text;\n"
			. "  'both'   takes the most frequent words in both texts combined;\n"
			. "  'corpus' takes the most frequent words in the entire corpus\n",
			
		dist =>
			"Maximum Distance means the greatest distance across which a set of matching "
			. "words may stretch within its unit. This can exclude 'sparse' matches.\n"
			. "\n"
			. "For example, the following matches across a distance of 4 in Lucan "
			. "and 1 in Vergil:\n"
			. "      Luc. BC.    1.477 AQUILAS collataque signa FERENTEM\n"
			. "      Verg. Aen. 11.752 FERT AQUILA\n"
			. "\n"
			. "Enter one or more integers, separated by commas;\n" 
			. "you may also specify a range using the form 'start - end [: step]', "
			. "for example:\n"
			. "   1 - 10          is equivalent to 1,2,3,4,5,6,7,8,9,10\n"
			. "  16 - 24 : 2      is equivalent to 16,18,20,22,24\n",

		dibasis =>
			"Distance Metric means the method by which max distance is calculated "
			. "in cases where more than two words match in each phrase.\n"
			. "Select one or more options, separated by commas:\n"
			. "  'span' takes the distance between the matching words that are furthest\n"
			. "         apart in each phrase, adding the values for soure and target.\n"
			. "  'freq' takes the distance between the two lowest-frequency matching words\n"
			. "         in each phrase, adding the values together.  The idea here is to\n"
			. "         try to zero in on the words most important to the intertext.\n"
			. "  'span-target' uses the span in the target text only\n"
			. "  'span-source' likewise, but in the source text only\n"
			. "  'freq-target' uses the lowest frequency words in the target only\n"
			. "  'freq-source' likewise, but in the source text only\n"
	);
	
	my %choices = (
	
		source   => $all_texts,
		target   => $all_texts,
		unit     => [qw/line phrase/],
		feature  => [qw/word stem syn 3gr/],  
		stop     => ['any integer'],
		stbasis  => [qw/target source both corpus/],
		dist     => ['any integer'],
		dibasis  => [qw/span span-target span-source freq freq-target freq-source/]
	);
	
	my %name = (

		source   => 'Source Text',
		target   => 'Target Text',
		unit     => 'Unit',
		feature  => 'Feature',
		stop     => 'Stoplist Size',
		stbasis  => 'Stoplist Basis',
		dist     => 'Maximum Distance',
		dibasis  => 'Distance Metric'
	);
	
	my %default = (
	
		unit     => 'line',
		feature  => 'stem',
		stop     => 10,
		stbasis  => 'both',
		dist     => 999,
		dibasis  => 'freq'
	);

	#
	# set up terminal interface
	#

	my $term = Term::ReadLine->new('myterm');
		
	# prompt for source, target
	
	for my $dest (@params) {

		my %options = (

			print_me => 
				$name{$dest} . ":\n"
				. "Please enter one or more values.  Type 'choices' to see allowable\n"
				. "options, 'help' for detailed instructions, or 'quit' to quit.\n",
				
			prompt  => "$dest: "
		);
				
		if ($default{$dest}) {
		
			$options{default} = $default{$dest};
			
			# for some reason a ':' is added by get_reply
			# when there's a default, but not otherwise
			
			$options{prompt} =~ s/://;
		}

		until ($par{$dest}) {					
	
			my $reply = $term->get_reply(%options);
			
			next unless $reply;
		
			if ($reply =~ /^help/i) {
			
				print STDERR "\n";
				print STDERR $help{$dest};
			}
			elsif ($reply =~ /^choices/i) {
			
				print STDERR "\n";
				print STDERR "Choices for $dest:\n";
			
				if ($#{$choices{$dest}} > 6) {
				
					my $list;
					
					for (my $i = 0; $i < $#{$choices{$dest}}; $i++) {
						
						$list .= "  $choices{$dest}[$i]\n";
						
						if ($i+1 % 20 == 0) {
						
							print STDERR $list;
							print STDERR '==more==';
							<STDIN>;
							print STDERR "\n";
						}
					}
					
					print $list;
				}
				else {
				
					print STDERR "  " . join(', ', @{$choices{$dest}}) . "\n";
				}
			}
			elsif ($reply =~ /^quit/i) {
			
				exit;
			}
			else {
			
				$par{$dest} = $reply;
			}

			print STDERR "\n";
		}
	}	
	
	until ($file_output) {

		$file_output = $term->get_reply(
			prompt => 'Enter an output file name: '
		);
		
		if (-e $file_output) {
		
			my $confirm = $term->ask_yn(
				prompt  => "$file_output already exists--overwrite? ",
				default => 'n');
				
			redo unless $confirm;
		}	
	}
}


#
# write config file
#

sub write_config {

	my ($file, $ref) = @_;
	
	my %par = %$ref;
	
	open (my $fh, '>:utf8', $file) or die "can't write $file: $!";
	
	for my $key (keys %par) {
	
		print $fh "[$key]\n";
		
		for my $val (@{$par{$key}}) {
		
			print $fh "$val\n";
		}
		
		print $fh "\n";
	}
	
	close ($fh);
}