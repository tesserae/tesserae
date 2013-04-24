# textlist.pl
#
# add texts to the drop-down menus

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

use Storable qw(nstore retrieve);
use File::Basename;

#
# these lines set language-specific variables
# such as what is a letter and what isn't
#

my %abbr;
my $file_abbr = catfile($fs{data}, 'common', 'abbr');
	
if ( -s $file_abbr )	{  %abbr = %{retrieve($file_abbr)} }

my %lang;
my $file_lang = catfile($fs{data}, 'common', 'lang');

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

			push @ARGV, (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

			closedir (DH);
		}

		next;
	}

	# the header for the column will be the filename 
	# minus the path and .tess extension

	my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
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

my $multi_counter = 1;

for my $lang (keys %text) {
                   
   my $base = catfile($fs{html}, "textlist.$lang");
	
	open (FHL, ">", "$base.l.php");
	open (FHR, ">", "$base.r.php");
	open (FHM, ">", "$base.multi.php");     
	
	print FHM "<table>\n<tr>\n";

	for my $name ( sort @{$text{$lang}} ) {
	
		print STDERR "adding $name\n";

		my $display = $name;

		$display =~ s/\./ - /g;
		$display =~ s/\_/ /g;

		$display =~ s/\b([a-z])/uc($1)/eg;

		print FHL "<option value=\"$name\">$display</option>\n";

		print FHM "</tr>\n<tr>\n" if ($multi_counter % 2);
		$multi_counter ++;

		print FHM "\t<td><input type=\"checkbox\" name=\"include\" value=\"$name\">$display</input></td>\n";                            
		
		if ( defined $part{$name} ) {

			print FHR "<optgroup label=\"$display\">\n";
			
#			print FHR "   <option value=\"$name\">$display - Full Text</option>\n";
		
			for my $part ( sort { $a <=> $b } @{$part{$name}}) {
				
				print FHR "   <option value=\"$name.part.$part\">$display - Book $part</option>\n";
			}
			
			print FHR "</optgroup>\n";
		}
		else {
		
			print FHR "<option value=\"$name\">$display</option>\n";
		}
	}

	print FHM "</tr>\n</table>\n";

	close FHL;                    
	close FHR;                    
	close FHM;
}
