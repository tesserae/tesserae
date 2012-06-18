# how to draw a simple progress bar

package ProgressBar;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(ProgressBar);
	
sub new {
	my $self = {};
	
	$self->{END} = $_[1];
	
	$self->{COUNT} = 0;
	$self->{PROGRESS} = 0;
	
	print STDERR "0% |" . (" " x 40) . "| 100%";
	
	bless($self);
	return $self;
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	if (defined $incr)	{ $self->{COUNT} += $incr }
	else			   	   { $self->{COUNT}++ }
	
	$self->draw();
}

sub set {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new)	{ $self->{COUNT} = $new }
	else				{ $self->{COUNT} = 0 }
	
	$self->draw();
}

sub draw {

	my $self = shift;
	
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
		
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
		
		my $bars = int($self->{PROGRESS} * 41);
		if ($bars == 41) { $bars-- }
		
		print STDERR "\r" . "0% |" . ("#" x $bars) . (" " x (40 - $bars)) . "| 100%";
	}
	
	if ($self->{COUNT} >= $self->{END}) {
		
		$self->finish();
	}	
}

sub finish {

	print STDERR "\n";
}

1;