package Nikolaev;

use strict;
use Exporter;

our $VERSION   = 0.01;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

my %cols = (

	intertexts => [

		'run_id int',
		'unit_t int',
		'unit_s int',
		'score  int'
	],
	
	tokens => [
		'run_id int',
		'unit_t int',
		'unit_s int',
		'token  varchar(30)'
	]
);

sub cols {

	return %cols;	
}

sub process {

	my ($package, %opt) = @_;
	
	my %meta  = %{$opt{meta}};
	my %match = %{$opt{target}};
	my %score = %{$opt{score}};
	
	my $sth_intertext = $opt{dbh}->prepare(
		"insert into intertexts values (?, ?, ?, ?);"
	);
	
	my $sth_token = $opt{dbh}->prepare(
		"insert into tokens values (?, ?, ?, ?);"
	);
		
	my $pr = ProgressBar->new(scalar(keys %match), $opt{verbose} == 1);
	
	for my $unit_id_target (keys %match) {
		
		$pr->advance;
		
		for my $unit_id_source (keys %{$match{$unit_id_target}}) {
			
			$sth_intertext->execute(
				$opt{run_id},
				$unit_id_target, 
				$unit_id_source, 
				$score{$unit_id_target}{$unit_id_source}
			);
			
			for my $token_id (keys %{$match{$unit_id_target}{$unit_id_source}}) {
			
				my $key = join("-", keys %{$match{$unit_id_target}{$unit_id_source}{$token_id}});
				
				$sth_token->execute(
					$opt{run_id},
					$unit_id_target,
					$unit_id_source,
					'"' . $key . '"'
				);
			}
		}
	}	
}

1;