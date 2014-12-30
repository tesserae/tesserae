#!/usr/bin/env perl

=head1 NAME

inspect-bin.pl - inspect stored corpus data

=head1 SYNOPSIS

name.pl NAME FEAT ID

=head1 DESCRIPTION

Display the stored representation of entry ID in table FEAT for text NAME.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<NAME>

The name of a text in the corpus.

=item I<FEAT>

The name of a table.

=item I<ID>

The row id of the table.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is inspect-bin.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

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

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable;

# initialize some variables

my $help = 0;

# get user options

GetOptions(
	'help'  => \$help);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

binmode STDOUT, ":utf8";

my ($name, $table, $id) = @ARGV;

my $file = catfile($fs{data}, 'v3', Tesserae::lang($name), $name, "$name.$table");

my $ref = retrieve($file);

if (ref($ref) eq "HASH") { 

	my %index = %$ref;
	
	print expand($index{$id}) if defined $index{$id};
}
elsif (ref($ref) eq "ARRAY") {

	my @val = @$ref;
	
	print expand($val[$id]) if defined $val[$id];
}


sub expand {

	my ($ref, $indent) = @_;
	
	$indent = 0 unless defined $indent;

	return 
		ref($ref) eq "HASH"   ? expand_hash($ref, $indent)   :
		ref($ref) eq "ARRAY"  ? expand_array($ref, $indent)  :
		ref($ref) eq "SCALAR" ? expand_scalar($ref, $indent) :
								$ref;
}

sub expand_hash {

	my ($ref, $indent) = @_;
	
	$indent++;
	
	my %index = %$ref;
	
	my $return = " "x($indent-1) . "{\n";
	
	while (my ($key, $value) = each %index) {
			
		$return .= " "x$indent . sprintf("%-9s => %s\n", $key, expand($value, $indent));
	}
	
	$return .= " "x($indent-1) . "}\n";
}

sub expand_array {

	my ($ref, $indent) = @_;
	
	my @array = @$ref;
	
	for (@array) {
	
		my $val = expand($_, $indent);
	
		if ($val =~ /\D/) { $val = "\"$val\"" }
		
		$_ = $val;
	}
	
	my $nl = ($indent ? "" : "\n");
	
	return "[" . join(", ", @array) . "]$nl";
}

sub expand_scalar {

	my ($ref, $indent) = @_;
	
	return "$$ref\n";
}
