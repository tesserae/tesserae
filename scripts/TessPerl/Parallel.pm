=head1 NAME

Parallel.pm	- organize parallel phrases

=head1 SYNOPSIS

use Parallel;
my $parallel = Parallel->new(
	target      => 'lucan.bellum_civile.part.1',
	target_loc  => '1.359',
	target_text => 'expromere voces',
	source      => 'vergil.aeneid',
	source_loc  => '2.279',
	source_text => 'expromere voces',
	auth        => ['Roche'],
	type        => 4,
	comment     => '',

	target_unit => 215,
	source_unit => 525,
	score       => 5.1234
);

=head1 DESCRIPTION

=head1 KNOWN BUGS

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is Parallel.pm.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

package Parallel;

use strict;
use Exporter;

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
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;

use Tesserae;
use EasyProgressBar;

# additional modules

use Storable;

# set some parameters

our $VERSION   = 3.00;
our @ISA       = qw(Exporter);
our @EXPORT    = ();
our @EXPORT_OK = ();

#
# allowable attributes
#

my @options = qw/
	target
	target_loc
	target_text
	source
	source_loc
	source_text
	auth
	type
	comment

	target_unit
	source_unit
	score
/;


#
# labels for attributes
#  - matches dump() below

sub header {

	return @options;
}

#
# constructor
#

sub new {
	
	my ($package, %opt) = (@_);

	my $self = {};
	
	bless($self, 'Parallel');

	$self->set(%opt);
	
	return $self;
}

#
# getter
#

sub get {

	my ($self, $attr) = @_;
		
	return $self->{$attr};
}

#
# setter
#

sub set {

	my ($self, %opt) = @_;
	
	my @set = @{Tesserae::intersection([keys %opt], \@options)};
	
	for (@set) {
				
		$self->{$_} = $opt{$_};
	}
	
	return $self;
}

#
# add a commentator to an array
#

sub append_auth {

	my ($self, $auth) = @_;
	
	push @{$self->{auth}}, $auth;
	
	return $self;
}

#
# append more comments to a string
#

sub append_comment {

	my ($self, $comment) = @_;
	
	if (defined $self->{comment} and length($self->{comment} > 0)) {
	
		$self->{comment} .= ' ' . $comment;
	}
	else {
	
		$self->{comment} = $comment;
	}
	
	return $self;
}

#
# match by attributes
#

sub match {

	my ($self, %opt) = @_;
	
	for (@options) {

		next unless defined $opt{$_};
		
		if (defined $self->{$_}) {
		
			return 0 unless $self->{$_} == $opt{$_};
		}
		else {
		
			return 0 unless $opt{match_na};
		}
	}
	
	return 1;
}

#
# merge data from another parallel into this one
#

sub merge {

	my ($self, $other, %opt) = @_;
	
	my %set;
	
	for (@options) {
		
		my $mine = ($self->get($_)  or '');
		my $his  = ($other->get($_) or '');
		
		if (($his and not $mine) or
			($his and $mine and $opt{clobber})) {
		
			$set{$_} = $his;
		}		
	}
	
	$self->set(%set);
	
	return $self;
}

#
# dump the whole record
#

sub dump {

	my ($self, %opt) = @_;
	
	my $na = $opt{na};
	
	my @dump;
	
	my @select = @options;
	
	if (defined $opt{select}) {

		@select = @{$opt{select}}
	}
	
	for (@select) {
		
		my $val = $self->get($_);
		
		unless (defined $val) { 

			$val = $na; 
		}
		
		if (ref($val) ne 'ARRAY') {
			
			push @dump, $val;
		}
		else {
			
			my @val = map {defined $_ ? $_ : $na} @$val;
			
			push @dump, ($opt{join} ? join($opt{join}, @val) : @val);
		}
	}
		
	for (@dump) {
		
		if ($opt{w}) {
		
			$_ = sprintf("%.${opt{w}}s", $_);
		}
	}

	if ($opt{lab}) {
	
		for (0..$#dump) {
		
			$dump[$_] = join("=", $select[$_], $dump[$_]);
		}
	}
	
	return @dump;
}

1;