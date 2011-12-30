#! /usr/local/bin/perl

use lib '/Users/chris/sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use Files;

$|++;

my @file;
my $dry_run = 0;
my $clean = 0;
my $in_file = "";

my $usage = <<END;
usage: v2.batch-prepare-texts.pl [-hdcc] [-f FILE]
    -h   help: this message
    -d   dry-run: don\'t make any changes
    -c   clean: delete any old processed files first
    -cc  clean cache: same as -c but also delete stem cache
    -f   read from FILE: FILE should be a list of .tess file labels (not full pathnames; texts are assumed to be in $fs_text).  One label per line.  Use -f - to read from stdin.
    
    The default behavior is to process all .tess files in $fs_text while attempting to preserve existing preprocessed data (e.g.  $fs_data/v2/ and its subdirectories).
END

while (my $test = shift @ARGV)
{
	if ($test =~ /^-/) 
	{
		if ($test =~ /d/) 
		{
			$dry_run = 1;
		}

		if ($test =~ /c/) 
		{
			$clean = 1;

			if ($test =~ /cc/)
			{
				$clean_cache=1;
			} 
		}
		
		if ($test =~ /f/) 
		{
			$in_file = shift @ARGV;
		}

		if ($test =~ /h/) 
		{
			die $usage;
		}
	}
}

my @temp;

if ($in_file eq "")
{
	opendir (DH, $fs_text);

	@temp = (grep {/\.tess$/ && -f} map { "$fs_text/$_" } readdir DH);

	closedir DH;
}
elsif ($in_file eq "-")
{
	@temp = (<>);
}
else
{
	open FH, "<$in_file" or die "Can't open $in_file: $!";
	@temp = (<FH>);
	close FH;
}

for my $file (@temp) 
{
	chomp $file;
	
	$file =~ s/.+\///;

	$file =~ s/\s+$//;

	$file =~ s/\.tess$//;
	
	if (-r "$fs_text/$file.tess")
	{
		push @file, $file;
	}
	else
	{
		print STDERR "$fs_text/$file.tess does not exist or is not readable by ";
		print STDERR (getpwuid($>))[$0] . "\n";
	}
}

if ($clean == 1)
{
	print STDERR "Cleaning...\n";

	do_cmd("rm $fs_html/textlist.v2.php");	
	do_cmd("rm $fs_data/v2/parsed/*");
	do_cmd("rm $fs_data/v2/preprocessed/*");

}

unless ((-r "$fs_data/v2/stem.cache") and ($clean_cache != 1))
{ 
	do_cmd ("touch $fs_data/v2/stem.cache");
}
unless ((-r "$fs_data/v2/tesserae.datafiles.config") and ($clean != 1))
{ 
	do_cmd ("touch $fs_data/v2/tesserae.datafiles.config");
}


print STDERR "Parsing " . ($#file+1) . " files...\n";

for my $file (@file)
{
	if ((-r "$fs_data/v2/parsed/$file.parsed") and ($clean != 1))
	{
		print STDERR "$fs_data/v2/parsed/$file.parsed already exists; skipping.\n";
	}
	else
	{
		do_cmd("perl $fs_perl/prepare.pl $fs_text/$file.tess");
	}
}

print STDERR "\n\n" . "Preprocessing " . ($#file+1) * $#file / 2 . " comparisons...\n";

my $counter = 0;

for (my $a = 0; $a <= $#file; $a++)
{
	for (my $b = $a+1; $b <= $#file; $b++)
	{
	
		$counter++;

		my $preexisting = Files::preprocessed_file($file[$a], $file[$b]);
		if ( defined($preexisting) )
		{ 
		
			print STDERR "comparison $file[$a] / $file[$b] already has an index entry\n";

			if ( -r "$fs_data/v2/preprocessed/$preexisting" )
			{
				print STDERR "and parallel cache $fs_data/v2/preprocessed/$preexisting exists...skipping\n";
				next;
			}

			print STDERR "but parallel cache $fs_data/v2/preprocessed/$preexisting does not exist...proceeding\n";
		}	
		else
		{
			do_cmd("echo '$file[$a]\t$file[$b]\t$file[$a].tess\t$file[$b].tess\t$file[$a]\~$file[$b]' >> $fs_data/v2/tesserae.datafiles.config");
		}
	
		do_cmd("perl $fs_perl/preprocess.pl $file[$a] $file[$b]");
	}
}

print STDERR "Adding files to HTML drop-down menu...\n";

for my $file (sort @file)
{
	my $title = $file;
	$title =~ s/_/ /g;
	$title =~ s/\./ - /;

	while ($title =~ /\b([a-z])/g)
	{
		my $lc = $1;
		my $uc = uc($lc);
		$title =~ s/\b$lc/$uc/;
	}

        my $execstring = "grep '$file' $fs_text/textlist.vs.php"; 

	if ((`$execstring` eq "") and ($clean != 1))
	{
		print STDERR "$file already has an entry; skipping\n";
                next;
	}
	
	do_cmd(qq{echo '<option value="$file">$title</option>' >> $fs_html/textlist.v2.php'});
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
