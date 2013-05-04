#
# part.pl
#
# segment large .tess files into multiple parts

use File::Copy;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions;
use File::Basename;
use Getopt::Long;
use utf8;

my $div;

GetOptions('div=s' => \$div);

while (my $file = shift @ARGV) {

	unless ( -r $file ) {
	
		print STDERR "can't read $file; skipping\n";
		next;
	}

	# split the file in to path, name, suffix

	my ($name, $path, $suffix) = fileparse($file, qr/\.[^.]*/);

	# create a directory with the same name as the file

	my $dir = catdir($path, $name);

	rmtree($dir);
	mkpath($dir);

	#
	# process the file
	#

	my $nlines;

	my $n = -1;
	my $last_n = -1;

	open (IF, "<:utf8", $file);
	binmode ":utf8", STDOUT;

	while (my $line = <IF>) {
	
		if ( $line =~ /^\S*<(.+?)>/ ) {

			$n = $1;

			$n =~ s/.*\s+//;
			$n =~ s/\..*//;
			
			$line =~ s/^\S</</;
		}

		if ($n ne $last_n) {
			
			my $file_out = catfile($dir, "$name.part.$n.tess");

			print STDERR "$nlines lines\n" unless $last_n == -1;

			open (OF, ">:utf8", $file_out);
			select OF;

			print STDERR "writing $file_out\n";

			$nlines = 0;
		}

		print $line;

		$nlines++;

		$last_n = $n;
	}

	print STDERR "$nlines lines\n";

	close OF;
	close IF;
}
