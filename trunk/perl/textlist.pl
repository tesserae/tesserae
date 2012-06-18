#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

# textlist.pl
#
# add texts to the drop-down menus

use strict;
use warnings; 

use Storable qw(nstore retrieve);

use TessSystemVars;

#
# these lines set language-specific variables
# such as what is a letter and what isn't
#

my %abbr;
my $file_abbr = "$fs_data/common/abbr";
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

my %lang;
my $file_lang = "$fs_data/common/lang";

if (-s $file_lang )	{ %lang = %{retrieve($file_lang)} }

my $lang;
my $lang_override;
my %text;
my %part;

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV)
{

	# allow language to be set from cmd line args

	if ($file_in =~ /^--(la|grc)/)
	{
		$lang_override = $1;
		next;
	}

	#
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if ($file_in !~ /\.tess/)
	{
		if (-d $file_in)
		{
			opendir (DH, $file_in);

			push @ARGV, (grep {/\.part\./ && -f} map { "$file_in/$_" } readdir DH);

			closedir (DH);
		}

		next;
	}

	# the header for the column will be the filename 
	# minus the path and .tess extension

	my $name = $file_in;

	$name =~ s/.*\///;
	$name =~ s/\.tess$//;

	# get the language for this doc.  try:
	# 1. user specified at cmd line
	# 2. cached from a previous successful parse
	# 3. somewhere in the path to the text
	# - then give up

	if ( defined $lang_override )
	{
		$lang = $lang_override;
	}
	elsif ( defined $lang{$name} )			
	{ 
		$lang = $lang{$name};
	}
	elsif ($file_in =~ /\/(la|grc)\//)
	{
		$lang = $1;
	}
	else
	{
		die "please specify language using --la|grc";
	}

	if ($name =~ /(.+)\.part\.(\d+)/)
	{
		push @{$part{$1}}, $2;
	}
	else
	{
		push @{$text{$lang}}, $name;
	}

	if ( ! defined $lang{$name} ) 
	{ 
		$lang{$name} = $lang;
		nstore \%lang, $file_lang;
	}
}

for my $lang (keys %text)
{

	open (FHL, ">", "$fs_html/textlist.$lang.l.php");
	open (FHR, ">", "$fs_html/textlist.$lang.r.php");

	for my $name ( sort @{$text{$lang}} )
	{
		my $display = $name;

		$display =~ s/\./ - /g;
		$display =~ s/\_/ /g;

		$display =~ s/\b([a-z])/uc($1)/eg;

		print FHL "<option value=\"$name\">$display</option>\n";
		
		if ( defined $part{$name} ) {

			print FHR "<optgroup label=\"$name\">\n";
			
			print FHR "   <option value=\"$name\">$display - Full Text</option>\n";
		
			for my $part ( sort { $a <=> $b } @{$part{$name}}) {
				
				print FHR "   <option value=\"$name.part.$part\">$display - Book $part</option>\n";
			}
			
			print FHR "</optgroup>\n";
		}
		else {
		
			print FHR "<option value=\"$name\">$display</option>\n";
		}
	}

	close FH;
}
