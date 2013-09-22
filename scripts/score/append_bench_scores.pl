#!/usr/bin/env perl

=head1 NAME

append_bench_scores.pl - collate search results with benchmark data

=head1 SYNOPSIS

append_bench_scores.pl [options] <RESULTS | --session SESSION>

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<RESULTS>

Name of directory containing Tesserae results.

=item B<--session> SESSID

Process sesssion SESSID in the I<tmp/> directory.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is append_bench_scores.pl.

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

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;
use Parallel;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use CGI qw(:standard);
use Storable;

#
# initialize some variables
#

my $session;

my $quiet = 0;

my $file_bench = catfile($fs{data}, 'bench', 'rec.cache');

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# commandline options
#

GetOptions(
	"bench=s"   => \$file_bench,
	"session=s" => \$session,
	"quiet"     => \$quiet
	);

#
# CGI options
#

unless ($no_cgi) {
	
	print header('-charset'=>'utf-8', '-type'=>'text/html');
	
	$session = $query->param('session');	
	$quiet   = 1;
} 

#
# the file to read
#

my $file_tess;

if (defined $session) {

	$file_tess = catfile($fs{tmp}, "tesresults-" . $session);
}
else {
	
	$file_tess = shift @ARGV;
}

unless (defined $file_tess) {
	
	if ($no_cgi) {

		pod2usage(1);
	}
	else {
		$session = "NA";
		html_no_session();
	}
	exit;
}

#
# read the data
#

# benchmark set

print STDERR "reading benchmark set $file_bench\n" unless $quiet;

my $bench = read_bench($file_bench);

# tesserae

print STDERR "reading tesserae data from $file_tess\n" unless $quiet;

my $tess = read_tess($file_tess);

#
# merge
#

$bench = merge($tess, $bench);

# print results

if   ($no_cgi) { export($bench) }
else           {}


#
# subroutines
#

#
# output subroutines
#

sub export {

	my ($bench_ref, $q_) = @_;
	my @bench = @$bench_ref;
	my $q = ($q_ or $quiet);
	
	print STDERR "exporting " . scalar(@bench) . " records\n" unless $q;
	
	print join("\t", Parallel::header) . "\n";
	
	my $pr = ProgressBar->new(scalar(@bench), $q);
	
	for my $p (@bench) {
		
		$pr->advance;
		
		# don't print rows that haven't been annotated for type
		
		next unless defined $p->get('type');
	
		print join("\t", $p->dump(na=>'NA', join=>';')) . "\n";
	}
}

sub html_no_session {
}

#
# read benchmark file
#

sub read_bench {

	my $file = shift;
	
	my @bench = @{retrieve($file)};
	
	my $pr = ProgressBar->new(scalar(@bench), $quiet);
	
	for (@bench) {
		
		$pr->advance();
	
		my %rec = %$_;
		
		my %opt = (
			target      => 'lucan.bellum_civile.part.1',
			target_loc  => join('.', $rec{BC_BOOK}, $rec{BC_LINE}),
			target_text => $rec{BC_TXT},
			source      => 'vergil.aeneid',
			source_loc  => join('.', $rec{AEN_BOOK}, $rec{AEN_LINE}),
			source_text => $rec{AEN_TXT},
			auth        => $rec{AUTH},
			type        => $rec{SCORE},
			target_unit => $rec{BC_PHRASEID},
			source_unit => $rec{AEN_PHRASEID}
		);
		
		$_ = Parallel->new(%opt);
	}
	
	return \@bench;
}

#
# read tesserae data
#

sub read_tess {

	my $file = shift;
	
	my @tess;
		
	my %meta          = %{retrieve(catfile($file, 'match.meta'))};
	my %match_score   = %{retrieve(catfile($file, 'match.score'))};

	my $pr = ProgressBar->new(scalar(keys %match_score), $quiet);

	for my $unit_id_target (keys %match_score) {
		
		$pr->advance();
	
		for my $unit_id_source (keys %{$match_score{$unit_id_target}}) {
			
			my %opt = (
				
				target      => $meta{TARGET},
				source      => $meta{SOURCE},
				target_unit => $unit_id_target,
				source_unit => $unit_id_source,
				score       => $match_score{$unit_id_target}{$unit_id_source}
			);
			
			push @tess, Parallel->new(%opt);
		}
	}
	
	return \@tess;
}

#
# merge the tess results and the bench results,
# combining parallels that refer to the same 
# phrase pairs
#

sub merge {

	my ($ref_a, $ref_b) = @_;
		
	my @a = @$ref_a;
	my @b = @$ref_b;
	
	my %index;
	my @merged;
	
	print STDERR "indexing...\n" unless $quiet;
	
	my $pr = ProgressBar->new(scalar(@a) + scalar(@b), $quiet);
	
	for (@a, @b) {
		
		$pr->advance();
		
		push @{$index{$_->get('target_unit')}{$_->get('source_unit')}}, $_;
	}
	
	print STDERR "merging...\n" unless $quiet;
	
	$pr = ProgressBar->new(scalar(keys %index), $quiet);
	
	for my $unit_id_target (keys %index) {
		
		$pr->advance();
		
		for my $unit_id_source (keys %{$index{$unit_id_target}}) {
		
			my $p = Parallel->new();

			my @to_be_merged = @{$index{$unit_id_target}{$unit_id_source}};
			
			for (@to_be_merged) {
		
				$p->merge($_);
			}

			push @merged, $p;
		}
	}
	
	return \@merged;
}