use Cwd;
use File::Copy;

# this should be the full path to the configure script

my $perl_path = getcwd() . "/$0";

# assume the library is in the same directory

$perl_path =~ s/\/configure.pl$//;

# this array will hold a list of perl files to check

my @perl_files;

# go to the $perl_path directory and identify all perl scripts/modules

opendir (DH, $perl_path);

push @perl_files, (grep {/\.pl|m$/ && -f} map { "$perl_path/$_" } readdir DH);

closedir (DH);

# make installation specific changes.

# first perl files.
#
# what they need is a single line at the beginning telling them where
# local modules will be stored
#

for my $file (@perl_files)
{	
	print STDERR "configuring $file\n";

	open IPF, "<$file";
	open OPF, ">$file.configured";
			
	while (my $line = <IPF>)
	{
		if ($line =~ /^use lib .+#\s*PERL_PATH/)
		{
			$line = "use lib '$perl_path';	# PERL_PATH\n";
		}
		
		print OPF $line;
	}
	
	close IPF;
	close OPF;
	
	move( "$file.configured", $file) or die "move $file.configured $file failed: $!";
}

