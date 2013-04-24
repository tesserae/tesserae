#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Desktop/tesserae/perl';	# PERL_PATH

#
# 3gr.test.pl
#
# visualize 3-gram frequencies
#

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

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use CGI::Session;
use CGI qw/:standard/;

use Storable qw(nstore retrieve);
use File::Path qw(mkpath rmtree);

#
# initialize set some parameters
#

# text to parse 

my $target = 0;

# unit

my $unit = 'line';

# length of memory effect in units

my $memory = 10;

# used to calculated the decay exponent

my $decay = .5;

# print debugging messages to stderr?

my $quiet = 0;

# 3-grams to look for; if empty, use all available

my $keys = 0;

# choose top n 3-grams

my $top = 0;

# for progress bars

my $pr;

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{retrieve($file_abbr)};

# language database

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

#
# initialize cgi, session objects
#

my $cgi = CGI->new() || die "$!";

my $session = CGI::Session->new(undef, $cgi, {Directory => '/tmp'});

# print header

print $session->header(-encoding=>"utf8");

#
# show the details of the original search
#

my $file_template = catfile($fs{html}, "3gr.init.tmpl");

my $details = details_table();


#
# create the three menus for colour assignment
#

my $form = start_form(-action=>"$url_cgi/3gr.display.pl")
		 . keys_menus()
		 . submit(-name=>'submit', -value=>'Display')
		 . end_form();

#
# load the page template
#

my $file_php = catfile($fs{html}, "3gr.template.php");

my $frame = `php -f $file_php`;


# insert the generated html

my $html = <<END;

		<div>
			<h2>Search Details</h2>
			$details
		</div>
		<div>
			<h2>Select 3-grams to assign to primary colours</h2>
			
			$form
		</div>
		
END

$frame =~ s/<!--content-->/$html/;

print $frame;


#
# subroutines
#

sub details_table {

	my @row;

	for (qw/target unit decay top/) {
	
		push @row, td([$_, $session->param($_)]);
	}

	my $table = table(
		Tr(\@row)
		);

	return $table;
}

sub keys_menus {

	# get the keys from the session data

	my $kref   = $session->param("keys")   || [];
	my @keys   = @$kref;
	
	# create a hash pointing each key to its index in the array
	
	my %labels;

	for (0..$#keys) {

		$labels{$_} = $keys[$_];
	}
	
	# a special value for "no assignment"

	$labels{-1} = 'none';
	
	# numeric values for the choices
	
	my @values = (-1..$#keys);

	# names of the menus

	my @names = qw/red green blue/;
	
	# arrange the three menus in a table
	
	my $table = table(
		Tr([
			th(\@names),
			td([
				popup_menu('red',   \@values, -1, \%labels),
				popup_menu('green', \@values, -1, \%labels),
				popup_menu('blue',  \@values, -1, \%labels)
				])
		]));
		
	return $table;
}