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
	
	$self->{COUNT} = 0;
	$self->{PROGRESS} = 0;
	$self->{QUIET} = $quiet;
	
	bless($self);
	
	$self->draw();
	
	return $self;
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	if (defined $incr)	   { $self->{COUNT} += $incr }
	else			   	   { $self->{COUNT}++ }
	
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
	
	if ($self->{QUIET} == 0) {
	
		if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
		
			$self->{PROGRESS} = $self->{COUNT} / $self->{END};
		
			my $bars = POSIX::floor($self->{PROGRESS} * 40);
		
			print STDERR "\r" . "0% |" . ("#" x $bars) . (" " x (40 - $bars)) . "| 100%";
		}
	}
	
	if ($self->{COUNT} >= $self->{END}) {
		
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
		
		my $bars = POSIX::floor($self->{PROGRESS} * 40);
		
		print STDERR "\r" . "0% |" . ("#" x $bars) . (" " x (40 - $bars)) . "| 100%";
		
		$self->finish();
	}	
}

sub finish {

	if ($self->{QUIET} == 0) {

		print STDERR "\n";
	}
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
	
	$self->{COUNT} = 0;
	$self->{PROGRESS} = 0;
	$self->{QUIET} = $quiet;
	
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
	
	if (defined $incr)	   { $self->{COUNT} += $incr }
	else			   	   { $self->{COUNT}++ }
	
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
		
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .025) {
	
		my $oldbars = POSIX::floor($self->{PROGRESS} * 40);
	
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
	
		my $bars = POSIX::floor($self->{PROGRESS} * 40);
									
		my $add = "<td class=\"pr_unit\">.</td>" x ($bars - $oldbars);
	
		print $add;
	}
	
	if ($self->{COUNT} >= $self->{END}) {
		
		my $oldbars = POSIX::floor($self->{PROGRESS} * 40);
	
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
	
		my $bars = POSIX::floor($self->{PROGRESS} * 40);
									
		my $add = "<td class=\"pr_unit\">.</td>" x ($bars - $oldbars);
	
		print $add;
		
		$self->finish();
	}	
}

sub finish {

	print "</tr></table>\n";
	print "</div>\n";
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