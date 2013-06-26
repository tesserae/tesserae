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
use File::Basename;
use File::Temp;

# initialize some variables

my $help;
my $verbose = 1;
my $manage  = 0;
my $lang    = 'la';
my $no_dup  = 0;

my %cl_opt = (
	parallel   => undef,
	manage     => undef,
	session    => undef,
	dir_parent => undef,
	cleanup    => undef,
	plugin     => undef
);

my @param_names = qw/
	source
	target
	unit
	feature
	stop
	stbasis
	dist
	dibasis/;

my $dir_client = catdir($fs{tmp},  'batch');
my $dir_manage = catdir($fs{data}, 'batch');

#
# get user options
#

# from command line

GetOptions(
	'help'       => \$help,
	'session=s'  => \$cl_opt{session},
	'quiet'      => sub { $verbose = 0 },
	'verbose'    => sub { $verbose++ },
	'cleanup!'   => \$cl_opt{cleanup},
	'plugin=s@'  => \$cl_opt{plugin},
	'parallel=i' => \$cl_opt{parallel},
	'parent=s'   => \$cl_opt{dir_parent},
	'no_dup'     => \$no_dup,
	'manage'     => \$manage
);

# print usage if the user needs help

if ($help) {

	pod2usage(1);
}

# get file to read from first cmd line arg

my $config = shift(@ARGV);

if (! defined $config) {

	pod2usage(1);
}

# parse file to get search parameters

my $ref   = parse_config($config);
my %param = %$ref;

# options specified on cmd line override those in config

for (keys %cl_opt) {
	
	if (defined $cl_opt{$_}) {
		
		$param{$_} = $cl_opt{$_};
	}
}

# validate parameters

%param = %{validate(\%param)};

my $session = init_session($param{session}, $param{dir_parent});

my @plugins = @{$param{plugin}};

my $cleanup = defined($param{cleanup}) ? $param{cleanup} : 1;

# get all combinations

my @run = @{combi(\%param)};

if ($no_dup) { @run = @{remove_intratext(\@run)} }

#
# try to load Parallel::ForkManager
#   - if requested.

my ($parallel, $pm) = init_parallel($param{parallel});

#
# create database
#

# create the database

($param{dir_work}, $param{file_db}) = init_db($session);

#
# preamble
#

print STDERR "Performing " . scalar(@run) . " Tesserae searches\n" if $verbose;

my $pr = ProgressBar->new(scalar(@run), ($verbose != 1));

my $dbh_manage;

if ($manage) {
	
	$dbh_manage = init_manage($pr);
	write_status($dbh_manage, $pr);
}

#
# main loop
#

for (my $i = 0; $i <= $#run; $i++) {

	$pr->advance();
	
	# maintenance tools
	
	if ($manage) {

		write_status($dbh_manage, $pr);
		
		if (check_kill($dbh_manage, $config)) {

			write_status($dbh_manage, $pr, -1);
			die "batch run terminated";
		}
	}
	
	# fork
	
	if ($parallel) {
	
		$pm->start and next;
	}
	
	# create directory for tess output based on session, run_id
	
	my $bin = catfile($param{dir_work}, $i);
	
	# join params to make shell command
	
	my $cmd = make_run(@{$run[$i]}, '--bin' => $bin);
		
	exec_run($cmd);
	
	#
	# connect to database
	#
	
	my $dbh = DBI->connect("dbi:SQLite:dbname=$param{file_db}", "", "");
	
	# load tesserae data from the results files
	
	my ($meta, $target, $source, $score) = parse_results($bin);
		
	#
	# process all plugins
	#
	
	for my $plugin (@plugins) {
		
		print STDERR "Processing $plugin\n" if $verbose > 1;
	
		my %opt = (
		
			run_id      => $i,
			target      => $target,
			source      => $source,
			meta        => $meta,
			score       => $score,
			param_names => \@param_names,
			dbh         => $dbh,
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

export_tables($session, $param{file_db}, "\t");

#
# remove working files
#

if ($cleanup) {

	print STDERR "Cleaning up\n" if $verbose;

	rmtree($param{dir_work});
}

#
# make results readable by everyone
#

chmod 0755, $session;

#
# clear data for pickup by web user
#

write_status($dbh_manage, $pr, 1) if $manage;

#
# subroutines
#

#
# initialize parallel processing
#

sub init_parallel {

	my $parallel = shift;
	
	my $pm;
	
	my $override = Tesserae::check_mod('Parallel::ForkManager');

	if ($parallel && $override) {
		
		$parallel = 0;
	}
	
	if ($parallel) {
		
		$pm = Parallel::ForkManager->new($parallel);
	}
	
	return ($parallel, $pm);
}

#
# create a new database
#

sub init_db {

	my $session = shift;

	#	
	# create the database file
	#
	
	my $file_db = catfile($session, 'sqlite.db');
	
	if (-e $file_db) {
		
		unlink $file_db;
	}
		
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file_db", "", "");
	
	# create necessary tables
	
	my %cols = ();
	
	for my $plugin (@plugins) {

		%cols = (%cols, $plugin->cols);
	}
	
	for my $table (keys %cols) {
		
		create_table($dbh, $table, $cols{$table});
	}
	
	$dbh->disconnect;
	
	#
	# create a working directory for all the tesserae results
	#
	
	my $dir_work = catdir($session, 'working');
	rmtree($dir_work);
	mkpath($dir_work);
	
	return ($dir_work, $file_db);
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

	my ($session, $file_db, $delim) = @_;
		
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file_db", "", "");

	print STDERR "Exporting data\n" if $verbose;
		
	for my $plugin (@plugins){
		my %cols = $plugin->cols;
		
		for my $table (keys %cols) {
	
			my $sth = $dbh->prepare("select * from $table;");
		
			$sth->execute;
		
			my $file = catfile($session, "$table.txt");
		
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

	my ($dbh, $table, $cols) = @_;
	
	my $sth = $dbh->prepare(
		'select name from sqlite_master 
			where type="table" and name="' . $table . '";'
	);
	
	my $exists = $sth->fetchrow_array;
	
	if ($exists) {
	
		$sth = $dbh->prepare("drop table $table;");
		$sth->execute;
	}
	
	$sth = $dbh->prepare(
		"create table $table (" . join(",", @$cols) . ");"
	);
	$sth->execute;
}

#
# check for presence of kill flag set by web interface
# 

sub check_kill {

	my $dbh_manage = shift;
	
	# short version of session
	
	my $session_ = $session;
	$session_    = substr($session_, -4, 4);
	
	# check for flag set through the web interface
	# but if the client db doesn't exist, don't create it
	
	my $flag_client = 0;
	
	my $db_client = catfile($dir_client, 'queue.db');
		
	if (-e $db_client) {
		
		my $dbh_client = DBI->connect("dbi:SQLite:dbname=$db_client", "", "");
		
		$flag_client = $dbh_client->selectrow_arrayref(

			"select KILL from queue where SESSION = '$session_';"
		);
	
		if (defined $flag_client) {

			 $flag_client = $flag_client->[0];
		}
		
		$dbh_client->disconnect;
	}
	
	# check for flag set by manager
	
	my $flag_manage = $dbh_manage->selectrow_arrayref(

		"select STATUS from queue where SESSION = '$session_';"
	);
	
	$flag_manage = (defined($flag_manage) and $flag_manage->[0] == -1) ? 1 : 0;
	
	return ($flag_client or $flag_manage);
}

#
# record initialization params for management script
#

sub init_manage {

	my $pr = shift;

	# make sure session management directory exists

	unless (-d $dir_manage) {
	
		mkpath($dir_manage) or die "can't create directory $dir_manage: $!";
	}
	
	# connect to database
	
	my $db_manage  = catfile($dir_manage, 'queue.db');
	
	my $dbh_manage = DBI->connect("dbi:SQLite:dbname=$db_manage", "", "");
	
	# make sure table exists
	
	my $exists = $dbh_manage->selectrow_arrayref(
		
		'select name from sqlite_master where type="table" and name="queue";'
	);
	
	# create it if it doesn't
	
	unless ($exists) {
		
		my $sth = $dbh_manage->prepare(
			'create table queue (
				SESSION char(4),
				START   int,
				TIME    int,
				NRUNS   int,
				RUNID   int,
				STATUS  int
			);'
		);
		
		$sth->execute;
	}

	# short form of session
	
	my $session_ = $session;
	$session_    = substr($session_, -4, 4);
	
	#
	# create an entry for this batch
	#

	my @values = (
		"'$session_'", 
		time,
		"NULL",
		$pr->terminus,
		"NULL",
		0
	);
		
	my $sth = $dbh_manage->prepare(
		'insert into queue values(' . join(',', @values) . ');'
	);
	
	$sth->execute;
	
	return $dbh_manage;
}


#
# record progress so that others can see it
#

sub write_status {

	my ($dbh, $pr, $flag) = @_;
		
	my $time  = time;
	my $runid = $pr->count;
	
	my $session_  = $session;
	$session_     = substr($session_,  -4, 4);
	
	my @values = (
		
		"TIME   = $time",
		"RUNID  = $runid"
	);
	
	if (defined $flag) {
		
		push @values, "STATUS = $flag";
	}
	
	my $sth = $dbh->prepare(
 		"update queue set " . join(',', @values) . " where SESSION='$session_';"
	);	
	
	$sth->execute;
}

#
# parse a config file for parameters
#

sub parse_config {

	my $file = shift;
	
	open (FH, "<", $file) || die "can't open $file: $!";
	
	my $text;
	
	while (my $line = <FH>) {
	
		$text .= $line;
	}
	
	close FH;
	
	$text =~ s/[\x12\x15]+/\n/sg;
	
	my %section;
	
	my $pname = "";
	
	my @line = split(/\n+/, $text);
	
	my @all = @{Tesserae::get_textlist($lang)};
	
	for my $l (@line) {

		# remove comments

		$l =~ s/#.*//;
		
		# skip empty lines
		
		next unless $l =~ /\S/;
		
		# look for section headers
		
		if ($l =~ /\[\s*(\S.+).*\]/) {
		
			$pname = lc($1);
			next;
		}	
		
		# look for range syntax
		
		if ($l =~ /range\s*\(from\D*(\d+)\b.*?to\D*(\d+)(.*)/) {
		
			my ($from, $to, $tail) = ($1, $2, $3);
			
			my $step = 1;
			
			if (defined $tail and $tail =~ /step\D*(\d+)/) {
			
				$step = $1;
			}
			
			$l = seq($from, $to, $step);
		}
		elsif ($l =~ /(\d+)\s*-\s*(\d+)(.*)/) {
		
			my ($from, $to, $tail) = ($1, $2, $3);
			
			my $step = 1;
			
			if (defined $tail and $tail =~ /:\s*(\d+)/) {
			
				$step = $1;
			}
			
			$l = seq($from, $to, $step);
		}
		
		# add to current section
							
		push @{$section{$pname}}, $l;
	}
	
	# flatten lists to a single line,
	#  remove whitespace
	#  drop blanks
	
	for (keys %section) {
	
		$param{$_} = join(',', @{$section{$_}});
		$param{$_} =~ s/\s//g;
		$param{$_} = [grep { /\S/ } split(/,/, $param{$_})];		
	}
	
	#
	# convert params that take only one option from array to scalar
	#
	
	for (qw/session dir_parent cleanup parallel/) {
	
		if (defined $param{$_}) {
			
			$param{$_} = $param{$_}[0];
		}
	}
	
	return \%param;
}

#
# parse command-line options 
# for multiple values, ranges
#

sub validate {
	
	my $ref = shift;
	my %param = %$ref;
	
	my $flag = 0;
	
	# expand text names for source, target
		
	for my $pname (qw/source target/) {
		
		unless (defined $param{$pname}) {
		
			$param{$pname} = [];
		}
	
		my @pass;
		my @all = @{Tesserae::get_textlist($lang, -sort=>1)};

		for my $val (@{$param{$pname}}) {
		
			$val =~ s/\./\\./g;
			$val =~ s/\*/.*/g;
			$val = "^$val\$";
			
			push @pass, (grep { /$val/ } @all);
		}
		
		if (@pass) {
		
			$param{$pname} = Tesserae::uniq(\@pass);
		}
		else {
		
			$flag = 1;
			warn "No matching texts for $pname";
		}
	}
	
	# 
	# validate remaining params that take strings
	#

	my %allowed = (
	
		unit     => [qw/line phrase/],
		feature  => [qw/word stem syn 3gr/],  
		stbasis  => [qw/target source both corpus/],
		dibasis  => [qw/span span-target span-source freq freq-target freq-source/]
	);
	
	for my $pname (keys %allowed) {
		
		unless (defined $param{$pname}) {
		
			$param{$pname} = [];
		}
		
		my @pass;
		
		for my $val (@{$param{$pname}}) {
		
			if (grep {$val eq $_} @{$allowed{$pname}}) {
			
				push @pass, $val;
			}
		}
		
 		unless (@pass) {
		
			warn "No matching values for $pname";
			$flag = 1;
		}
		
		$param{$pname} = \@pass;
	}

	for my $pname (qw/stop dist/) {
	
		unless (defined $param{$pname}) {

			$param{$pname} = [];
		}
		
		my @val = map { int($_) } @{$param{$pname}};
	
		unless (@val) {
			
			warn "No allowable values for $pname";
			$flag = 1;
		}
		
		$param{$pname} = \@val;
	}
	
	#
	# validate plugins
	#   - load those that pass

	push @{$param{plugin}}, 'Runs';

	for my $plugin (@{$param{plugin}}) {

		$plugin =~ s/[^a-z_].*//i;

		if (-s catfile($fs{script}, 'batch', 'plugins', $plugin . '.pm')) {

			eval "require batch::plugins::$plugin";
		}
		else {

			warn "Invalid plugin: $plugin";
		}
	}

	# fail if any section didn't validate

	if ($flag) {
	
		die "Can't validate config $config";
	}

	#
	# remove duplicate entries from all sections
	#
	
	for my $pname (keys %param) {
		
		if (ref($param{$pname}) eq 'ARRAY') {
			
			$param{$pname} = Tesserae::uniq($param{$pname});
		}
	}

	return \%param;
}

#
# generate a sequence of integers
#

sub seq {

	my ($from, $to, $step) = map { int($_) } @_;
		
	if ($from > $to) {
	
		($from, $to) = ($to, $from);
	}
	
	if ($step < 0) {
	
		$step *= -1;
	}
	
	if ($step == 0) {
	
		$to = $from;
	}
	
	my @seq;
	
	for (my $i = $from; $i <= $to; $i += $step) {
	
		push @seq, $i;
	}
	
	my $seq = join(',', @seq);

	return $seq;
}

#
# calculate all combinations of params
#

sub combi {

	my $ref = shift;
	my %param = %$ref;
	
	my @combi = ([]);

	for my $pname (@param_names) {

		my @combi_ = @combi;
		@combi = ();

		for my $cref (@combi_) {

			for my $val (@{$param{$pname}}) {

				push @combi, [@{$cref}, "--$pname" => $val];
			}
		}
	}
		
	return \@combi;	
}


#
# write a command that executes a tess search from params
#

sub make_run {

	my (@tess_options) = @_;
	
	my $script = catfile($fs{cgi}, 'read_table.pl');
	
	my $cmd = join(" ",
		$script,
		@tess_options,
		'--quiet'
	);
	
	return $cmd;
}

#
# generate a session directory if none provided
#

sub init_session {

	my ($file_out, $dir) = @_;
	
	if ($file_out) {
		
		if ($dir) {
		
			$file_out = catfile($dir, $file_out);
		}
			
		if (-e $file_out) {
			rmtree($file_out) or die "can't overwrite existing session $file_out: $!";
		}
		
		mkpath($file_out) or die "can't create session $file_out: $!";
	}
	else {
		
		$dir = ($dir || curdir);
	
		$file_out = File::Temp::tempdir(
			'tesbatch.XXXX',
			DIR => $dir
		);
	}
	
	$file_out = abs_path($file_out);
	
	chmod 0744, $file_out;

	return $file_out;
}


#
# remove runs that have source and target the same
#

sub remove_intratext {

	my $ref = shift;
	
	my @combi = @$ref;

	@combi = grep {
		
		my %tessopt = (@$_);
		$tessopt{'--source'} ne $tessopt{'--target'};
	} @combi;
	
	return \@combi;
}