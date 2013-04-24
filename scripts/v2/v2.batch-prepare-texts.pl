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
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use File::Basename;
use Getopt::Long;

# initialize variables

$|++;

my @file;
my $clean = 0;
my $clean_cache = 0;
my $dry_run = 0;
my $file_batch = "";
my $help = 0;

my $fs_v2 = catfile($fs{data}, 'v2');

my $usage = <<END;
usage: v2.batch-prepare-texts.pl [options] [--batch FILE]

options:

	--batch FILE   read list of texts to process from FILE instead of
                     command-line arguments.
    --clean        delete any old processed files first
    --dry-run      don't make any changes
    --help         this message
	
    The default behavior is to process all .tess files in $fs{text}
    while attempting to preserve existing preprocessed data 
    (i.e. $fs_v2 and its subdirectories).
END

GetOptions(	'batch=s' => \$file_batch,
			'clean'   => \$clean,
			'cache'   => \$clean_cache,
			'dry-run' => \$dry_run,
			'help'    => \$help);

if ($help) {

	print $usage;
	exit;
}

my @temp;

if ($file_batch eq "")
{
	opendir (DH, catdir($fs{text}, 'la'));

	@temp = (grep {/\.tess$/ && -f} map { catfile($fs{text}, $_)} readdir DH);

	closedir DH;
}
else
{
	open FH, "<$file_batch" or die "Can't open $file_batch: $!";
	@temp = (<FH>);
	close FH;
}

for my $file_in (@temp) 
{
	chomp $file_in;
	
	my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
	my $file_text = catfile($fs{text}, "$name.tess");
	
	if (-r $file_text)
	{
		push @file, $name;
	}
	else
	{
		print STDERR "$file_text does not exist or is not readable by ";
		print STDERR (getpwuid($>))[$0] . "\n";
	}
}

if ($clean)
{
	print STDERR "Cleaning...\n";

	do_cmd('rm ' . catfile($fs{html}, 'textlist.v2.php'));
	do_cmd('rm ' . catfile($fs{data}, 'v2', 'parsed', '*'));
	do_cmd('rm ' . catfile($fs{data}, 'v2', 'preprocessed', '*'));

}

my $file_stem_cache = catfile($fs{data}, 'v2', 'stem.cache');

unless (-s $file_stem_cache and $clean_cache == 0)
{ 
	do_cmd ("touch $file_stem_cache");
}

my $file_v2_config = catfile($fs{data}, 'v2', 'tesserae.datafiles.config');

unless ((-r $file_v2_config) and ($clean != 1))
{ 
	do_cmd ("touch $file_v2_config");
}


print STDERR "Parsing " . ($#file+1) . " files...\n";

for my $name (@file)
{
	my $file_parsed = catfile($fs{data}, 'v2', 'parsed', "$name.parsed");

	if ((-r $file_parsed) and ($clean != 1))
	{
		print STDERR "$file_parsed already exists; skipping.\n";
	}
	else
	{
		do_cmd(join(" ", 'perl', catfile($fs{script}, 'prepare.pl'), 
								 catfile($fs{text}, "$name.tess")));
	}
}

print STDERR "\n\n" . "Preprocessing " . ($#file+1) * $#file / 2 . " comparisons...\n";

my $counter = 0;

for (my $a = 0; $a <= $#file; $a++)
{
	for (my $b = $a+1; $b <= $#file; $b++)
	{
	
		$counter++;

		my $file_preprocessed = catfile($fs{data}, 'v2', 'preprocessed',
							 join("~", sort @file[$a,$b]) . '.preprocessed');

		if ( -r "$file_preprocessed" )
		{
			print STDERR "$file_preprocessed exists...skipping\n";
			next;
		}
	
		do_cmd(join(' ', 'perl', catfile($fs{script}, 'preprocess.pl'), @file[$a,$b]));
	}
}

print STDERR "Adding files to HTML drop-down menu...\n";

for my $name (sort @file)
{
	my $title = $name;
	$title =~ s/_/ /g;
	$title =~ s/\./ - /;

	while ($title =~ /\b([a-z])/g)
	{
		my $lc = $1;
		my $uc = uc($lc);
		$title =~ s/\b$lc/$uc/;
	}

	my $file_textlist = catfile($fs{text}, 'textlist.v2.php');

    my $execstring = "grep '$name' $file_textlist"; 

	if ((`$execstring` eq "") and ($clean != 1))
	{
		print STDERR "$name already has an entry; skipping\n";
                next;
	}
	
	do_cmd(qq{echo '<option value="$name">$title</option>' >> $file_textlist'});
}


sub do_cmd 
{
	my $cmd_string = shift @_;
	
	print STDERR $cmd_string . "\n";
	unless ($dry_run == 1) 
	{
		print STDERR `$cmd_string`;
	}
}
