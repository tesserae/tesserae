#
# part.pl
#
# segment large .tess files into multiple parts

use File::Copy;

while (my $file = shift @ARGV)
{

	unless ( -r $file )
	{
		print STDERR "can't read $file; skipping\n";
		next;
	}

	# the base name is everything to the right of the last /
	# and left of the .tess extension

	$file =~ /(.*\/)(.*)\.tess/;

	my ($path, $name) = ($1, $2);

	mkdir($path.$name);

	my $nlines;

	my $n = -1;
	my $last_n = -1;

	open (IF, "<$file");
	open (OF, ">&STDERR");

	while (my $line = <IF>)
	{
		if ( $line =~ /^<(.+?)>/ )
		{
			$n = $1;

			$n =~ s/.*\s+//;
			$n =~ s/\..*//;
		}

		if ($n ne $last_n)
		{
			close OF;

			print STDERR "$nlines lines\n";

			open (OF, ">$path$name/$name.part.$n.tess");

			print STDERR "writing $path$name/$name.part.$n.tess\n";

			$nlines = 0;
		}

		print OF "$line";

		$nlines++;

		$last_n = $n;
	}

	close OF;
	close IF;
}
