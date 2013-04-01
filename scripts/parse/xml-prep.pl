use File::Copy;

while (my $oldfile = shift @ARGV) {

	my $newfile = $oldfile;
	$newfile =~ s/\.xml$/.modified.xml/;
	
	print STDERR "reading $oldfile\n";
	print STDERR "writing $newfile\n\n";
	
	open (IFH, "<", $oldfile) || die "can't read from $oldfile: $!";
	open (OFH, ">", $newfile) || die "can't write to $newfile: $!";
	
	while (<IFH>) {
		
		s/<\/?q.*?>/\&quot;/g;
		
		print OFH $_;
	}
	
	close IFH;
	close OFH;
}