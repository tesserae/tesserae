#! /opt/local/bin/perl5.12

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
my %text;
my %part;

#
# get files to be processed from cmd line args
#

while (my $file_in = shift @ARGV) {

	#
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if ($file_in !~ /\.tess/) {	

		if (-d $file_in) {

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

	# get the language for this doc from lang file
	
	$lang = $lang{$name};
	
	unless (defined $lang) { 

		 warn "$name doesn't seem to be in the database\nhave you run add_column.pl?";
		 next;
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

for my $lang (keys %text) {

	open (FHL, ">", "$fs_html/textlist.$lang.l.php");
	open (FHR, ">", "$fs_html/textlist.$lang.r.php");

	for my $name ( sort @{$text{$lang}} ) {
	
		print STDERR "adding $name\n";

		my $display = $name;

		$display =~ s/\./ - /g;
		$display =~ s/\_/ /g;

		$display =~ s/\b([a-z])/uc($1)/eg;

		print FHL "<option value=\"$name\">$display</option>\n";
		
		if ( defined $part{$name} ) {

			print FHR "<optgroup label=\"$display\">\n";
			
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

	close FHL;
	close FHR;
}
