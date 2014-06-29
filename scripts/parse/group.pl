use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;

my $lower;

GetOptions(
	'lower=s' => \$lower
);

my $dir = shift @ARGV;
my $base = $dir;
$base =~ s/.*\///;

my @lower = split(/,/, $lower);

my @group = ([]);
my @incl = ([]);

opendir(my $dh, $dir) or die "Can't read $dir: $!";
my @files = map {catfile($dir, $_)} grep {/\.part\./} readdir($dh);
closedir($dh);

for my $file (@files) {

	$file =~ /\.part\.(.+)\./;
	
	my $n = int($1);
	
	if ($n >= $lower[0]) {
		
		push @group, [];
		push @incl, [];
		shift @lower;
	}
	
	push @{$group[-1]}, $file;
	push @{$incl[-1]}, $n;
}

for my $i (1..$#group) {

	my $from = $incl[$i][0];
	my $to = $incl[$i][-1];

	my $op_file = catfile($dir, 'temp', "$base.part.$i.$from-$to.tess");

	my $cmdstr = join(' ', 'cat', @{$group[$i]}, '>', $op_file);
	
	print $cmdstr;
	print "\n";
}