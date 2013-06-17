package Recall;

use strict;
use Exporter;

# modules necessary to look for config

use Cwd qw/abs_path/;
use FindBin qw/$Bin/;
use File::Spec::Functions;

# load configuration file

my $tesslib;

BEGIN {
	
	my $dir  = $Bin;
	my $prev = "";
			
	while (-d $dir and $dir ne $prev) {

		my $pointer = catfile($dir, '.tesserae.conf');

		if (-s $pointer) {
		
			open (FH, $pointer) or die "can't open $pointer: $!";
			
			$tesslib = <FH>;
			
			chomp $tesslib;
			
			last;
		}
		
		$dir = abs_path(catdir($dir, '..'));
	}
	
	unless ($tesslib) {
	
		die "can't find .tesserae.conf!";
	}
}

# load Tesserae-specific modules

use lib $tesslib;

use Tesserae;
use EasyProgressBar;

# additional modules

use Data::Dumper;

# set some parameters

our $VERSION   = 0.01;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

# define tables & columns

my %cols = (

	'Recall_auth' => [
		'bench_id int',
		'auth_t1  int',
		'auth_t2  int',
		'auth_t3  int',
		'auth_t4  int',
		'auth_t5  int'
	],

	'Recall_tess' => [
		'run_id    int',
		'bench_id  int',
		'cutoff    int',
		'tess_t1   int',
		'tess_t2   int',
		'tess_t3   int',
		'tess_t4   int',
		'tess_t5   int',
		'both_t1   int',
		'both_t2   int',
		'both_t3   int',
		'both_t4   int',
		'both_t5   int'
	]
);

# cache benchmark numbers to avoid dups

my %bench_id;

sub cols {

	return %cols;	
}

#
# wrapper method for this package
#

sub process {

	my ($package, %opt) = @_;

	# call append_bench_scores

	my $tally = call_append_bench_scores(%opt);

	# calculate recall & precision

	export_rows($tally, %opt);	
	
}


#
# call append_bench_scores
#

sub call_append_bench_scores {

	my %opt = @_;

	my %tally;

	# call append_bench_scores

	my $script = catfile($fs{script}, 'benchmark', 'append_bench_scores.pl');

	if ($opt{verbose} < 2) {
	
		$script .= ' --quiet';
	}

	open (my $inputfh, "perl $script $opt{bin} |") or die "can't call append_bench_scores.pl: $!";

	# the header line

	my @head = @{get_rec($inputfh)};

	# the data

	while (my @val = @{get_rec($inputfh)}) {

		my %field;
		
		@field{@head} = @val;
		
		# skip all parallels not annotated for type
		
		next if $field{type} eq 'NA';

		# tally all found by tesserae

		if ($field{score} ne 'NA') {

			$tally{tess}[int($field{score})][$field{type}]++;
		}
		
		# tally commentator parallels
		
		if ($field{auth} ne 'NA') {
						
			$tally{auth}[$field{type}]++;
			$tally{auth}[0]++;
			
			# did tess find it too?

			if ($field{score} ne 'NA') {

				$tally{both}[int($field{score})][$field{type}]++;
			}	
		}
	}

	return \%tally;
}

#
# rationalize tallies
# 

#
# read a single row from append_bench_scores.pl
#

sub get_rec {

	my $fh = shift;
		
	my $line = <$fh>;
	
	my @field;
	
	if (defined $line) {

		chomp $line;
		@field = split(/\t/, $line);
	}
	
	return \@field;
}

#
# export data
#

sub export_rows {

	my ($tally, %opt) = @_;
	
	my %tally = %$tally;

	my @output;

	# commentator tallies
	#   - only export if we haven't seen
	#     these before
	
	my $key = join(":", @{$tally{auth}}[1..5]);
	
	unless (defined $bench_id{$key}) {
	
		$bench_id{$key} = scalar(keys %bench_id);
		
		my @row = ([($bench_id{$key}, @{$tally{auth}}[1..5])]);
		
		insert_row($opt{dbh}, 'Recall_auth', \@row);
	}
	
	# tesserae hits

	my @row;

	for (my $cutoff = $#{$tally{tess}}; $cutoff >= 0; $cutoff--) {
	
		my @row_ = ($opt{run_id}, $bench_id{$key}, $cutoff);
	
		for my $cat (qw/tess both/) {
	
			for (1..5) {
			
				$tally{$cat}[$cutoff][$_] +=
				
					defined $tally{$cat}[$cutoff+1] ? $tally{$cat}[$cutoff+1][$_]
						: 0;
				
				push @row_, $tally{$cat}[$cutoff][$_];
			}			
		}
		
		push @row, \@row_;
	}
	
	insert_row($opt{dbh}, 'Recall_tess', \@row);
}

#
# write rows to a table
#

sub insert_row {

	my ($dbh, $table, $row) = @_;
	my @row = @$row;

	my $sth = $dbh->prepare(
		"insert into $table values ("
		. join(', ', ('?') x scalar(@{$cols{$table}}))
		. ");"
	);

	for my $vals (@row) {

		$sth->execute(@$vals);
	}
}

1;