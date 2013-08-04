package Runs;

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

use Storable;

# set some parameters

our $VERSION   = 0.01;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

# cache unit counts for files

my %unit_count;

# table definition

sub cols {
		
	return (
		
			runs => [ 
			'run_id  int',
			'source  varchar(80)',
			'target  varchar(80)',
			'unit    char(6)',
			'feature char(4)',
			'stop    int',
			'stbasis char(7)',
			'dist    int',
			'dibasis char(11)',
			'cutoff  int',
			'words   int',
			'lines   int',
			'phrases int',
			'lemmata int'
		]
	);
}

#
# add run info to database
#

sub process {

	my ($package, %opt) = @_;
		
	my %meta = %{$opt{meta}};
	my @params = @meta{map {uc($_)} @{$opt{param_names}}};
	my @units  = @{units($meta{TARGET}, $meta{SOURCE})};
		
	my $values = join(', ', add_quotes(
		$opt{run_id}, 
		@params,
		@units,
		ntypes(@params[0,1])
	));
	
	my $sql = "insert into runs values ($values);";		
	my $sth = $opt{dbh}->prepare($sql);
	
	{ 
		$sth->execute and last;
		
		print STDERR "$! ...retrying\n";
		redo;
	}
}


#
# calculate the denominator to be used for unit normalization
#

sub units {

	my @text = @_;
	my @counts;
	
	for my $unit (qw/token line phrase/) {
	
		my $count = 1;
		
		for my $text (@text) {
		
			my $file = catfile($fs{data}, 'v3', 'la', $text, $text);
			$file .= ".$unit";
			
			my @unit = @{retrieve($file)};
			
			$count *= scalar(@unit);
		}
		
		push @counts, $count;
	}
	
	return \@counts;
}

#
# add quotes to text fields
#

sub add_quotes {

	for (@_) {
	
		$_ = "'$_'" if /[a-z]/i;
	}
	
	return @_;
}

#
# figure out how many different lemmata occur among the two texts
#

sub ntypes {

	my ($target, $source) = @_;
	
	my %combined;
	
	for ($target, $source) {
	
		my $file = catfile($fs{data}, 'v3', Tesserae::lang($_), $_, $_ . '.freq_stop_stem');
		my @list = @{Tesserae::stoplist_array($file)};
		
		for (@list) {
			$combined{$_} = 1;
		}
	}
	
	my $ntypes = scalar(keys %combined);
	
	return $ntypes;
}

1;