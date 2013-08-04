#!/usr/bin/env perl

=head1 NAME

parse.niko.pl - collate and prepare data for Dr. Nikolaev

=head1 SYNOPSIS

parse.niko.pl [options] SESSION

=head1 DESCRIPTION

Read output of batch.run.pl with Nikolaev plugin, prepare CSV tables 
as per Nikolaev's requirements.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is parse.niko.pl.

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

use Encode qw/encode decode/;

# initialize some variables

my $help  = 0;
my $quiet = 0;

# get user options

GetOptions(
	'quiet' => \$quiet,
	'help'  => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

#
# session is mandatory arg
#

my $session = shift(@ARGV);

unless (defined $session and -d $session) {

	warn "must specify session to read";
	pod2usage(1);
}

#
# copy metadata from Tesserae
#

copy_metadata(
	Authors => [0, 1, 3, 4, 5, 6],
	Texts   => [0, 1, 2, 4, 5, 7]
);

#
# retrieve text ids from txt file
#

my @text_id = @{index_runs()};

#
# read intertexts and index them 
#

my %intertext_id = %{index_intertexts()};

#
# subroutines
#

# copy Authors, Texts from Tesserae

sub copy_metadata {

	my %col_ref = @_;
	
	for my $name (keys %col_ref) {
		
		my $file_in  = catfile($fs{data}, 'common', 'metadata', $name . '.txt');
		my $file_out = catfile($session, ucfirst($name) . '.csv');
	
		open (my $fhi, "<:utf8", $file_in)  or die "can't read file $file_in: $!";
		open (my $fho, ">:utf8", $file_out) or die "can't read file $file_out: $!";
	
		print STDERR "copying $file_in to $file_out\n";
	
		while (my $row = <$fhi>) {
	
			chomp $row;
		
			my @field = split(/\t/, $row);
			
			unless (defined $col_ref{$name}) {
				
				$col_ref{$name} = [0..$#field];
			}
		
			print $fho join(',', @field[@{$col_ref{$name}}]) . "\n";
		}
	
		close $fhi;
		close $fho;
	}
}

# load text ids from file

sub load_text_ids {

	print STDERR "loading text ids\n" unless $quiet;

	my $file = catfile($fs{data}, 'common', 'metadata', 'Texts.txt');
	
	my %id;
	
	open (my $fh, "<:utf8", $file) or die "can't read file $file: $!";
	
	<$fh>;
	
	while (my $l = <$fh>) {
		
		my @field = split(/\t/, $l);
		
		next unless $#field == 7;
		
		$id{$field[6]} = $field[0];
	}
	
	return \%id;
}

sub index_runs {

	# load text ids

	my %id = %{load_text_ids()};
	
	#
	# for each run_id, we want target_id and source_id.
	#
	
	print STDERR "indexing runs\n" unless $quiet;
	
	my $file_in  = catfile($session, 'runs.txt');
	
	open (my $fh, '<:utf8', $file_in)  or die "can't read $file_in: $!";
	
	my @text_id;

	my $pr = ProgressBar->new(-s $file_in, $quiet);
	
	$pr->advance(length(decode('utf8', <$fh>)));
	
	while (my $row = <$fh>) {
		
		$pr->advance(length(decode('utf8', $row)));
		chomp $row;
	
		my @field = split(/\t/, $row);
		
		my ($run, $source, $target) = @field[0,1,2];
				
		$text_id[$run] = [$id{$target}, $id{$source}];
	}
	
	return \@text_id;
}

# translate runid, source, target into intertext id
# write Intertexts.csv at the same time, since it takes
# such a long time to go through the whole list of intertexts

sub index_intertexts {
		
	print STDERR "processing intertexts\n" unless $quiet;

	# open files
	
	my $file_in  = catfile($session, 'intertexts.txt');
	my $file_out = catfile($session, 'Intertexts.csv');
	
	open (my $fhi, '<:utf8', $file_in)  or die "can't read $file_in: $!";
	open (my $fho, '>:utf8', $file_out) or die "can't read $file_out: $!";

	# progress bar
	
	my $pr = ProgressBar->new(-s $file_in, $quiet);
	
	# header rows: skip for input file, write for output file

	$pr->advance(length(decode('utf8', <$fhi>)));
	print $fho join(",", qw/ID TARGET SOURCE UNIT_T UNIT_S SCORE/) . "\n";
	
	# $id is sequential id for intertexts, %index links id to run,unit_t,unit_s

	my $id = 0;
	my %index;
	
	while (my $row = <$fhi>) {
		
		$pr->advance(length(decode('utf8', $row)));
		chomp $row;
	
		# index the intertext
	
		my ($run, $unit_t, $unit_s, $score) = split(/\t/, $row);
		
		$index{$run}{$unit_t}{$unit_s} = $id;
		$id++;
				
		# make all scores 3 decimal places
		
		$score  = sprintf("%.3f", $score);
		
		# write to output file
		
		print $fho join(",", 
			$id,                  # intertext id
			$text_id[$run]->[0],  # target id
			$text_id[$run]->[1],  # source id
			$unit_t,              # target unit
			$unit_s,              # source unit
			$score                # score
		) . "\n";
		
	}
	
	return \%index;
}
