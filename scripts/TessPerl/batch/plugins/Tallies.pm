package Tallies;

use strict;
use Exporter;

our $VERSION   = 0.01;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

my %cols = (

	scores => [

		'run_id int',
		'score  int',
		'count  int'
	]
);

sub cols {

	return %cols;	
}

sub process {

	my ($package, %opt) = @_;
	
	my $row = get_tallies(%opt);
	
	write_row($opt{dbh}, $row);
}


sub get_tallies {

	my %opt = @_;
	
	unless (defined $opt{score} and ref($opt{score}) eq 'HASH') {
	
		die "Tallies::calc needs a reference to tesserae scores";
	}
	
	unless (defined $opt{run_id}) {
	
		die "Tallies::calc needs run_id";
	}
		
	# get score tallies

	my @tally;
	
	my %score = %{$opt{score}};

	for my $unit_id_target (keys %score) {
	
		for my $unit_id_source (keys %{$score{$unit_id_target}}) {
		
			my $score_round = sprintf('%.0f', $score{$unit_id_target}{$unit_id_source});
			$tally[$score_round]++;
		}
	}
	
	# format as table rows
	
	my @row;
	
	for (0..$#tally) {
		
		push @row, [$opt{run_id}, $_, ($tally[$_] || 0)];
	}
	
	return (\@row);
}

#
# write records to database table
#

sub write_row {

	my ($dbh, $row) = @_;
	my @row = @$row;
	
	my $sql = "insert into scores values ("
	        . join(", ", ('?') x scalar(@{$cols{scores}}))
	        . ");";
	
	my $sth = $dbh->prepare($sql);
	
	for (@row) {
	
		$sth->execute(@$_);
	}
}

1;