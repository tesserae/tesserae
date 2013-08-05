require Exporter;
use POSIX ();

our @ISA = qw(Exporter);

our @EXPORT = qw(ProgressBar HTMLProgress);

# how to draw a simple progress bar

package ProgressBar;
	
sub new {
	my $self = {};
	
	shift;
	
	my $terminus = shift || die "ProgressBar->new() called with no final value";
	
	$self->{END} = $terminus;
	
	my $quiet = shift || 0;
	
	$self->{COUNT}    = 0;
	$self->{PROGRESS} = 0;
	$self->{DONE}     = 0;
	$self->{T0}       = time;
	$self->{QUIET}    = $quiet;
	
	bless($self);
	
	$self->draw();
		
	return $self;
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	$self->{COUNT} += ($incr || 1);
	
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
		
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};

		$self->draw();
	}
	
	if ($self->{COUNT} >= $self->{END}) {
	
		$self->finish();
	}
}

sub set {

	my $self = shift;
	
	my $new = shift || 0;
	
	$self->{COUNT} = $new;
	
	$self->draw();
}

sub draw {

	my $self = shift;
		
	unless ($self->{QUIET} or $self->{DONE}) {
		
		my $bars = POSIX::floor($self->{PROGRESS} * 40);
	
		print STDERR "\r" . "0% |" . ("#" x $bars) . (" " x (40 - $bars)) . "| 100%" ;
	}
}

sub finish {

	my $self = shift;

	unless ($self->{QUIET} or $self->{DONE}) {

		print STDERR "\r" . "0% |" . ("#" x 40) . "| 100%\n";
	}
	
	$self->{DONE} = 1;	
}

sub progress {
	
	my $self = shift;
	
	return $self->{PROGRESS};
}

sub count {

	my $self = shift;
	
	return $self->{COUNT};
}

sub terminus {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new) {
	
		$self->{END} = $new;
		
		$self->draw();
	}
	
	return $self->{END};
}

#
# something equivalent for the web interface
# 

package HTMLProgress;

sub new {
	my $self = {};
	
	shift;
	
	my $terminus = shift;
	
	$self->{END} = $terminus;
	
	my $quiet = shift || 0;
	
	$self->{COUNT}    = 0;
	$self->{PROGRESS} = 0;
	$self->{QUIET}    = $quiet;
	$self->{DONE}     = 0;
	
	bless($self);
	
	$self->init();
	
	$self->draw();
	
	return $self;
}

sub init {

	$|++;

	print "<div class=\"pr_container\">\n";
	print "<table class=\"pr_bar\">\n";
	print "<tr>";
	print "<td class=\"pr_spacer\">0%</td>";
	print "<td class=\"pr_spacer\"></td>" x 38;
	print "<td class=\"pr_spacer\">100%</td>";
	print "</tr>\n";
	print "<tr>";
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	$self->{COUNT} += ($incr || 1);
	
	$self->draw();
}

sub set {

	my $self = shift;
	
	my $new = shift || 0;
	
	$self->{COUNT} = $new;
	
	$self->draw();
}

sub draw {

	my $self = shift;

	return if $self->{DONE};
		
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
	
		my $oldbars = POSIX::floor($self->{PROGRESS} * 40);
	
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
	
		my $bars = POSIX::floor($self->{PROGRESS} * 40);
									
		my $add = "<td class=\"pr_unit\">.</td>" x ($bars - $oldbars);
	
		print $add;
	}
	
	if ($self->{COUNT} >= $self->{END}) {
				
		$self->finish();
	}	
}

sub finish {

	my $self = shift;

	return if $self->{DONE};

	my $oldbars = POSIX::floor($self->{PROGRESS} * 40);

	$self->{PROGRESS} = $self->{COUNT} / $self->{END};

	my $bars = POSIX::floor($self->{PROGRESS} * 40);
								
	my $add = "<td class=\"pr_unit\">.</td>" x ($bars - $oldbars);

	print $add;

	print "</tr></table>\n";
	print "</div>\n";
	
	$self->{DONE} = 1;
}

sub progress {
	
	my $self = shift;
	
	return $self->{PROGRESS};
}

sub count {

	my $self = shift;
	
	return $self->{COUNT};
}

sub terminus {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new) {
	
		$self->{END} = $new;
		
		$self->draw();
	}
	
	return $self->{END};
}

# A modification of ProgressBar for very long running jobs

package VerySlowProgressBar;
	
sub new {
	my $self = {};
	
	shift;
	
	my $terminus = shift || die "VerySlowProgressBar->new() called with no final value";
	
	$self->{END} = $terminus;
	
	my $quiet = shift || 0;
	
	$self->{COUNT}    = 0;
	$self->{PROGRESS} = 0;
	$self->{DONE}     = 0;
	$self->{T0}       = time;
	$self->{REFRESH}  = .025;
	$self->{QUIET}    = $quiet;
	
	bless($self);
	
	$self->draw();
		
	return $self;
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	$self->{COUNT} += ($incr || 1);
	
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + $self->{REFRESH}) {
		
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};

		$self->draw();
	}
	
	if ($self->{COUNT} >= $self->{END}) {
	
		$self->finish();
	}
}

sub set {

	my $self = shift;
	
	my $new = shift || 0;
	
	$self->{COUNT} = $new;
	
	$self->draw();
}

sub t0 {

	my $self = shift;

	my $new = shift;

	if (defined $new) {

		$self->{T0} = $new;

		$self->draw();
	}

	return $self->{T0};	
}

sub draw {

	my $self = shift;
		
	unless ($self->{QUIET} or $self->{DONE}) {

		my $dur  = time - $self->{T0};
		my $rate = $self->{COUNT} / $dur;
		
		my $eta = $self->{T0} + $self->{END} / $rate;
		
		print STDERR sprintf("%.2f%% done; ETA %s", $self->{PROGRESS}, localtime($eta)) . "\n";
	}
}

sub finish {

	my $self = shift;

	unless ($self->{QUIET} or $self->{DONE}) {

		print STDERR "your very-long-running task is done!\n";
	}
	
	$self->{DONE} = 1;	
}

sub progress {
	
	my $self = shift;
	
	return $self->{PROGRESS};
}

sub count {

	my $self = shift;
	
	return $self->{COUNT};
}

sub terminus {

	my $self = shift;
	
	my $new = shift;
	
	if (defined $new) {
	
		$self->{END} = $new;
		
		$self->draw();
	}
	
	return $self->{END};
}


1;