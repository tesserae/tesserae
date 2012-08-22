#! /opt/local/bin/perl5.12

use lib '/var/www/html/chris/perl/';
use TessSystemVars;

my %file;
my @preprocessed;

print STDERR $#ARGV ."\n";

while (my $file = shift @ARGV) 
{
	chomp $file;
	
	$file =~ s/.+\///;

	$file =~ s/\s+$//;

	if ($file =~ /^(.+)\.vs\.(.+).preprocessed$/)
	{
		$file{$1} = 1;
		$file{$2} = 2;
		push @preprocessed, $file;
	}
}

my @file = sort (keys %file);

my $counter = 0;

open INDEX, '>' . $fs_data . 'v2/tesserae.datafiles.config';
open SH, ">v2_process.sh";

for (my $a = 0; $a <= $#file; $a++)
{
	unless (-s $fs_text . $file[$a] . '.tess')
	{
		print STDERR "Can't find " . $fs_text . $file[$a] . ".tess\n";
	}
	unless (-s $fs_data . 'v2/parsed/' . $file[$a] . '.parsed')
	{
		print STDERR "Can't find " . $fs_data . 'v2/parsed/' . $file[$a] . ".parsed\n";
	}


	for (my $b = $a+1; $b <= $#file; $b++)
	{
		my @prep = grep { /$file[$a]\.vs\.$file[$b]\.preprocessed/ || /$file[$b]\.vs\.$file[$a]\.preprocessed/ } @preprocessed;
		if ($#prep == -1)
 		{
			print STDERR "Pair $file[$a] / $file[$b] has no preprocessed file\n";
		}
		else
		{
			print INDEX "$file[$a]\t$file[$b]\t$file[$a].tess\t$file[$b].tess\t$prep[0]\n";
			print SH 'perl ' . $fs_perl . "preprocess.pl $file[$a] $file[$b]\n";
			$counter++
		}
	}
}
close INDEX;
close SH;

	print STDERR "Data are symmetrical.  Writing drop-down list.\n";

	open INDEX, '>' . $fs_html . 'textlist.v2.php';

	for my $file (@file)
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

        	print INDEX "<option value=\"$file\">$title</option>\n";
	}

