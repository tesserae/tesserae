#! /usr/bin/perl

use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH
use TessSystemVars;
use TessSystemVars qw(uniq intersection);

use Storable qw(nstore retrieve);
use File::Path qw(rmtree mkpath);

mkpath("$fs_data/ana");

for my $file_in (@ARGV) {		# files to parse are cmd line arguments

   ##################################
   # getting input
   ##################################

   my $short_name = $file_in;
   $short_name =~ s/^.*\///;		# remove path
   $short_name =~ s/\.tess//;		# and extension

   my $file_out = "$fs_data/ana/$short_name";

   print STDERR 'getting ' . $file_in . '...';

   open (FH, "<$file_in") || die "can't open $file_in: $!";

   my @rawdata = (<FH>);

   close FH;

   print STDERR $#rawdata . " lines\n";

   #######################################
   # clean the text
   #######################################

   print STDERR "anagrammizing...\n";

   my @locus;								# an array of line numbers

   my @word;                   		# strings of consecutive letters
	my @space;								# everything else. $space[0] comes before $word[0];
	
	my %index;
	my %anagram;
	
   for my $l (0..$#rawdata)						# for each line...
	{
		my $line = $rawdata[$l];
		
		chomp $line;
		
		my $loc;
		
		if  ( $line =~ s/<(.*)>\t// )
		{
			$loc = $1;
			
			if ($loc =~ /\s(\S+)$/)
			{
				$loc = $1;
			}
		}
		else
		{
			$loc = "";
		}
		
		push @locus, $loc;

		while ($line ne "")
		{
			$line =~ s/^(\W*)//;						# interword characters
			push @{$space[$l]}, $1;					#
			
			$line =~ s/^(\w*)//;						# word characters
			push @{$word[$l]}, $1;					#
		}	
	}
		
	nstore \@locus, "$file_out.locus";
	nstore \@word, "$file_out.word";
	nstore \@space, "$file_out.space";
	
	for my $l (0..$#word)
	{
		next if ($#{$word[$l]} < 0);
		
		for my $w (0..$#{$word[$l]})
		{
			my $word = ${$word[$l]}[$w];
			
			$word = lc ($word);									# convert to lowercase
			$word =~ tr/jv/iu/;									# get rid of orthographic variation
			
			push @{$index{$word}}, $l . '.' . $w;			# add line, pos to index under word
		}
	}
	
	delete $index{""};
	
	for my $word (keys %index)
	{
		my $ana = join("", sort( split( //, $word )));	# anagrammize
		push @{$anagram{$ana}}, $word;						# add word to list of anagrams
	}
	
	print STDERR "ana: scalar keys \%anagram=".scalar (keys %anagram)."\n";
		
	nstore \%anagram, "$file_out.ana";
	nstore \%index, "$file_out.index";
	
	my @ana_keys = grep { length($_) > 3 && $#{$anagram{$_}} > 0} keys %anagram;
	
	open FH, ">$file_out.html";
	
	print FH <<END;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>$short_name</title>

		<style type="text/css">
		div.header
		{
			margin-bottom: 2em;
		}
		div.header h1
		{
			font-size: 1em;
			font-weight: bold;
		}
		
		div.ana
		{
			width: 80%;
			margin-left: 5em;
		}
		div.ana div
		{
			margin-top: 1em;
			margin-bottom: 1em;
		}
		div.ana span
		{
		}
		div.ana span.head
		{
			position: absolute;
			left: .5em;
		}
		div.ana a
		{
			text-decoration: none;
		}
		div.ana a.marked
		{
			color: red;
		}

		</style>
	</head>

	<body>
		<div class="header">
			<h1>anagrams in $short_name</h1>
		</div>
		<div class="main">
END
	
	for my $key (sort { length($a) <=> length($b) } @ana_keys)
	{
		
		my %range;
		
		print FH '			<div class="ana">' . "\n";
		
		for my $word (sort @{$anagram{$key}})
		{

			for my $loc (@{$index{$word}})
			{

				my ($l,$w) = split(/\./, $loc);

#				print STDERR "word=$word\tloc=$loc: $locus[$l]\n";
				
				my $lrange = $l - ( $l >= 10 ? 10 : $l);
				my $rrange = $l + ( $l <= $#locus - 10 ? 10 : $#locus - $l );

#				print STDERR "lrange=$lrange\trrange=$rrange\n";

				for (my $i = $lrange; $i <= $rrange; $i++)
				{
					if ($locus[$i] ne "")
					{
						$range{$locus[$i]}++;
#						print STDERR "\t\$range{$locus[$i]}=$range{$locus[$i]}\n";
					}
				}
			}

		}
		for my $word (sort @{$anagram{$key}})
		{
			print FH "				<div><span class=\"head\">$word</span>";
			
			for my $loc (@{$index{$word}})
			{				
				my ($l,$w) = split(/\./, $loc);
				
#				print STDERR "word=$word\t\$range{$locus[$l]}=$range{$locus[$l]}\n";
				
				my $mark = ($range{$locus[$l]} >= 2 ? "class=\"marked\" " : "");
				
				print FH "<span><a href=\"$url_cgi/ana.session.pl?text=$short_name&word=$word#$locus[$l]\"$mark>$locus[$l]</a></span>\n";
			}
			print FH "</div>\n";
		}

		print FH "			</div>\n";
		print FH "<hr/>\n";
	}
	
	print FH <<END;
		</div>
	</body>
</html>
END

}