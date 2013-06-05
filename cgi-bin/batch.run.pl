#!/usr/bin/env perl

#
# batch.run.pl
#

=head1 NAME

batch.run.pl - run a batch of Tesserae searches and digest results

=head1 SYNOPSIS

batch.run.pl [options] FILE

=head1 DESCRIPTION

This script is meant to run a long list of Tesserae searches generated ahead of time by
'batch.prepare.pl'.  Creates a new directory, by default called 'tesbatch.000' or 
similar, in which are placed the following files:

=over

=item I<scores.txt>

A table giving, for each Tesserae run, the number of results returned at each integer
score.

=item I<runs.txt>

A second table giving, for each Tesserae run, all the search parameters used as well as
the time in seconds taken by that run.

=item I<sqlite.db>

A SQLite database containing the above two tables.

=item I<working/>

A subdirectory containing the results of all the individual Tesserae runs.

=back

Note: if B<cleanup> is set to true (the default), everything but the first two text 
files is deleted on completion.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<FILE>

The file of searches to perform, having been created by 'batch.prepare.pl'.

=item B<--dbname> I<NAME>

Name of a directory in which to store output.  Default is 'tesbatch.NNN' where N is a 
number.

=item B<--no-cleanup>

Don't delete working data, including all the individual Tesserae results.

=item B<--parallel> I<N>

Allow I<N> processes to run in parallel for faster results. 
Requires Parallel::ForkManager.

=item B<--quiet>

Less output to STDERR.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is batch.run.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

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
use Storable;
use File::Path qw/rmtree mkpath/;
use Data::Dumper;

# initialize some variables

my $help     = 0;
my $verbose  = 1;
my $parallel = 0;
my $cleanup  = 1;

my $dbname;
my $done;
my @plugin = qw/Runs/;

my @param_names = qw/
	source
	target
	unit
	feature
	stop
	stbasis
	dist
	dibasis/;

#
# is this script being called from the web or cli?
#

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

# html header

print header('-charset'=>'utf-8', '-type'=>'text/html') unless $no_cgi;

#
# get user options
#

# from command line

if ($no_cgi) {

	GetOptions(
		'cleanup!'   => \$cleanup,
		'dbname=s'   => \$dbname,
		'plugin=s'   => \@plugin,
		'help'       => \$help,
		'parallel=i' => \$parallel,
		'quiet'      => sub { $verbose = 0 },
		'verbose'    => sub { $verbose++ }
	);

	# print usage if the user needs help

	if ($help) {

		pod2usage(1);
	}

	# get file to read from first cmd line arg

	my $file = shift(@ARGV);

	unless ($file) { pod2usage(1) }
}
	
# from web interface
	
else {
		
}

#
# load plugin modules
#

for my $plugin (@plugin) {
	
	$plugin =~ s/[^a-z_].*//i;
	next unless -s catfile($fs{script}, 'Batch', $plugin . '.pm');

	eval "require Batch::$plugin";	
}

#
# try to load Parallel::ForkManager
#   - if requested.

($parallel, my $pm) = init_parallel($parallel);



my @run = @{parse_file($file)};


#
# create database
#

$dbname = check_dbname($dbname);
init_db($dbname);

my $datadir = catdir($dbname,  'working');
my $dbfile  = catfile($dbname, 'sqlite.db');


#
# main loop
#

print STDERR "Performing " . scalar(@run) . " Tesserae searches\n" if $verbose;

my $pr = ProgressBar->new(scalar(@run), ($verbose != 1));

for (my $i = 0; $i <= $#run; $i++) {

	$pr->advance();
	
	# fork
	
	if ($parallel) {
	
		$pm->start and next;
	}

	# modify arguments a little
	
	my $cmd = $run[$i];
	
	my $bin;
	
	$cmd =~ s/--bin\s+(\S+)/"--bin " . ($bin = catfile($datadir, $1))/e;
	$cmd .= ' --quiet' unless $verbose > 1;
	
	# run tesserae, note how long it took

	my $time = exec_run($cmd);
	
	#
	# connect to database
	#
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
	
	# load tesserae data from the results files
	
	my ($meta, $target, $source, $score) = parse_results($bin);
		
	#
	# process all plugins
	#
	
	for my $plugin (@plugin) {
		
		print STDERR "Processing $plugin\n" if $verbose > 1;
	
		my %opt = (
		
			run_id      => $i,
			bin         => $bin,
			target      => $target,
			source      => $source,
			meta        => $meta,
			score       => $score,
			param_names => \@param_names,
			dbh         => $dbh, 
			time        => $time,
			verbose     => $verbose
		);
			
		$plugin->process(%opt);
	}
	
	$dbh->disconnect;
	
	$pm->finish if $parallel;
}

$pm->wait_all_children if $parallel;

#
# export data to text files
#

export_tables($dbname, "\t");

#
# remove working files
#

if ($cleanup) {

	print STDERR "Cleaning up\n" if $verbose;

	rmtree($datadir);
	# unlink($dbfile);
}

#
# subroutines
#

#
# initialize parallel processing
#

sub init_parallel {

	my $parallel = shift;
	
	my $pm;
	
	if ($parallel) {

		eval {
		
			require Parallel::ForkManager;
		};
	
		if ($@) {
		
			print STDERR "can't load Parallel::ForkManager: $@\n";
			
			print STDERR "continuing with --parallel 0\n";
			
			$parallel = 0;
		}
	
		else {
		
			$pm = Parallel::ForkManager->new($parallel);
		}
	}
	
	return ($parallel, $pm);
}


#
# parse the input file
#

sub parse_file {

	my $file = shift;
	
	my @run;
	
	open(my $fh, "<", $file) or die "can't read $file: $!";
	
	print STDERR "reading $file\n" if $verbose;
	
	while (my $l = <$fh>) {
	
		chomp $l;
		push @run, $l if $l =~ /[a-z]/i
	}
	
	close $fh;
	
	return \@run;
}

#
# generate an output directory if none provided
#

sub check_dbname {

	my $dbname = shift;
	
	unless ($dbname) {
	
		opendir (my $dh, curdir) or die "can't read current directory: $!";
		
		my @existing = sort (grep {/^tesbatch\.\d+$/} readdir $dh);
		
		my $i = 0;
		
		if (@existing) {
		
			$existing[-1] =~ /\.(\d+)/;
			$i = $1 + 1;
		}
	
		$dbname = sprintf("tesbatch.%03i", $i);
		$dbname = abs_path(catfile(curdir, $dbname));
		
		mkpath($dbname);
	}
	else {

		$dbname = File::Spec::Functions::rel2abs($dbname);
	
		if (-e $dbname and not -d $dbname) {
	
			print STDERR "$dbname already exists and is not a directory.\n";
			print STDERR "Please choose a new name.\n";
			exit;
		}
		
		mkpath($dbname);
	}

	return $dbname;
}

#
# create a new database
#

sub init_db {

	my $dbname = shift;

	#	
	# open / create the database file
	#
	
	my $dbfile = catfile($dbname, 'sqlite.db');
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
	
	my %cols = ();
	
	for my $plugin (@plugin) {

		%cols = (%cols, $plugin->cols);
	}
	
	init_tables($dbh, %cols);
	
	$dbh->disconnect;
	
	#
	# create a working directory for all the tesserae results
	#
	
	my $working = catdir($dbname, 'working');
	rmtree($working);
	mkpath($working);
}


# figure out what tables are necessary
# and create them in the database

sub init_tables {

	my ($dbh, %cols) = @_;
	
	my %done;
	
	my $sth = $dbh->prepare(
		'select name from sqlite_master 
			where type="table";');
			
	$sth->execute;
	
	my %exists;
	foreach(@{$sth->fetchall_arrayref()}) {
		$exists{$_} = 1;
	}
		
	# init

	for my $table (keys %cols) {
		
		create_table($dbh, $table, $cols{$table}, $exists{$table});
	}
	
	return \%done;
}


#
# extract parameters from string
#

sub params_from_string {

	my $cmd = shift;
	my %par;
	
	$cmd =~ s/.*read_table.pl\s+//;
	
	while ($cmd =~ /--(\S+)\s+([^-]\S*)/g) {
	
		$par{$1} = $2;
	}
	
	return \%par;
}


#
# execute a run, return benchmark data
#

sub exec_run {

	my $cmd = shift;
	
	print STDERR $cmd . "\n" if $verbose > 1;
	
	my $bmtext = `$cmd`;
	
	$bmtext =~ /total>>(\d+)/;
	
	return $1;
}


#
# parse results files
#

sub parse_results {

	my $bin = shift;
	
	# get parameters
	
	my $file_meta = catfile($bin, 'match.meta');
	my $meta = retrieve($file_meta);
	
	my $file_score = catfile($bin, 'match.score');
	my $score = retrieve($file_score);
	
	# might use these later
	
	my $target;
	my $source;
		
	return ($meta, $target, $source, $score);
}

#
# export the two tables to flat files
#

sub export_tables {

	my ($dbname, $delim) = @_;
	
	my $dbfile = catfile($dbname, 'sqlite.db');
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

	print STDERR "Exporting data\n" if $verbose;
		
	for my $plugin (@plugin){
		my %cols = $plugin->cols;
		
		for my $table (keys %cols) {
	
			my $sth = $dbh->prepare("select * from $table;");
		
			$sth->execute;
		
			my $file = catfile($dbname, "$table.txt");
		
			open (FH, ">:utf8", $file) or die "can't write $file: $!";
			
			my @head = @{$cols{$table}};
			
			for (@head) {
				s/\s.*//;
			}
		
			print FH join($delim, @head) . "\n";
		
			while (my $ref = $sth->fetchrow_arrayref) {
		
				my @row = @$ref;
			
				print FH join($delim, @row) . "\n";
			}
		
			close FH;
		}
	}
	
	$dbh->disconnect;
}

sub create_table {

	my ($dbh, $table, $cols, $exists) = @_;
	
	my $sth;
	
	if ($exists) {
	
		$sth = $dbh->prepare("drop table $table;");
		$sth->execute;
	}
	
	$sth = $dbh->prepare(
		"create table $table (" . join(",", @$cols) . ");"
	);
	$sth->execute;
}