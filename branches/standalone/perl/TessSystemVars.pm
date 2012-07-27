use warnings;
use strict;

package TessSystemVars;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw($fs_perl $fs_text $fs_tmp $fs_data %is_word %non_word $split_punct);

our @EXPORT_OK = qw(uniq intersection tcase lcase beta_to_uni);

our $apache_user = "_www"; 

use FindBin qw($Bin);

my $fs_base	= "$Bin/..";

our $fs_perl 	= $Bin;
our $fs_data	= $fs_base . '/data';
our $fs_text	= $fs_base . '/texts';
our $fs_tmp  	= $fs_base . '/tmp';
our $fs_xsl  	= $fs_base . '/xsl';

# punctuation marks which delimit phrases

my $phrase_delimiter = '[\.\?\!\;\:]';

# a complicated regex to test for their presence
# if you match this $1 and $2 will be set to the parts
# belonging to the left and right phrases respectively

our $split_punct = qr/(.*"?$phrase_delimiter"?)(\s*)(.*)/;

#
# define what is a word char and what is non-word
# for various specific languages
#


my $wchar_greek = 'a-z\*\(\)\\\/\=\|\+\'';
my $wchar_latin = 'a-zA-Z';

our %non_word = (
	'la'      => qr([^$wchar_latin]+), 
	'grc'     => qr([^$wchar_greek]+),
	'unknown' => qr([^$wchar_latin]+) 
	);
our %is_word = (
	'la'      => qr([$wchar_latin]+), 
	'grc'     => qr([$wchar_greek]+),
	'unknown' => qr([$wchar_latin]+) 
	);
		   


########################################
# subroutines
########################################

sub uniq
{									
	# removes redundant elements

   my @array = @{$_[0]};			# dereference array to be evaluated

   my %hash;							# temporary
   my @uniq;							# create a new array to hold return value

	for (@array)	
	{ 
		$hash{$_} = 1; 
	}
											
   @uniq = sort( keys %hash);   # retrieve keys, sort them

   return \@uniq;
}


sub intersection 
{              

	# arguments are any number of arrays,
	# returns elements common to all as 
	# a reference to a new array

   my %count;			# temporary, local
   my @intersect;		# create the new array

   for my $array (@_) {         # for each array

      for (@$array) {           # for each of its elements (assume no dups)
         $count{$_}++;          # add one to count
      }
   }

	# keep elements whose count is equal to the number of arrays

   @intersect = grep { $count{$_} == 2 } keys %count;

	# sort results

   @intersect = sort @intersect;

   return \@intersect;
}

#
# language-specific lower-case and title-case functions
#

sub standardize {

	my $lang = shift;
	
	# if we don't know the language, assume latin rules
	
	if ($lang eq 'unknown') { $lang = 'la' }
	
	
	my @string = @_;
	
	for (@string) {
		
		$_ = lcase($lang, $_);
		
		if ($lang eq 'la')
		{
			tr/jv/iu/;	# replace j and v with i and u throughout
			s/[^a-z]//g;
		}
		
		if ($lang eq 'grc')
		{
			s/\\/\//;	# change grave accent (context-specific) to acute (dictionary form)
			s/0-9\.#//g;
		}
	}
	
	return wantarray ? @string : shift @string;	
}

sub lcase
{
	my $lang = shift;
	
	# if we don't know the language, assume latin rules
	
	if ($lang eq 'unknown') { $lang = 'la' }
	

	my @string = @_;

	for (@string)
	{
	
		if ($lang eq 'la')
		{
			tr/A-Z/a-z/;
		}
	
		if ($lang eq 'grc')
		{
			s/^\*([\(\)\/\\\|\=\+]*)([a-z])/$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}

sub tcase
{
	my $lang = shift;

	# if we don't know the language, assume latin rules
	
	if ($lang eq 'unknown') { $lang = 'la' }

	my @string = @_;
	
	for (@string)
	{

		$_ = lcase($lang, $_);

		if ($lang eq 'la')
		{
			s/^([a-z])/uc($1)/e;
		}
	
		if ($lang eq 'grc')
		{
			s/^([a-z])([\(\)\/\\\|\=\+]*)/\*$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}

sub beta_to_uni
{
	
	my @text = @_;
	
	for (@text)	{
		
		s/(\*)([^a-z ]+)/$2$1/g;
		
		s/\)/\x{0313}/ig;
		s/\(/\x{0314}/ig;
		s/\//\x{0301}/ig;
		s/\=/\x{0342}/ig;
		s/\\/\x{0300}/ig;
		s/\+/\x{0308}/ig;
		s/\|/\x{0345}/ig;
	
		s/\*a/\x{0391}/ig;	s/a/\x{03B1}/ig;  
		s/\*b/\x{0392}/ig;	s/b/\x{03B2}/ig;
		s/\*g/\x{0393}/ig; 	s/g/\x{03B3}/ig;
		s/\*d/\x{0394}/ig; 	s/d/\x{03B4}/ig;
		s/\*e/\x{0395}/ig; 	s/e/\x{03B5}/ig;
		s/\*z/\x{0396}/ig; 	s/z/\x{03B6}/ig;
		s/\*h/\x{0397}/ig; 	s/h/\x{03B7}/ig;
		s/\*q/\x{0398}/ig; 	s/q/\x{03B8}/ig;
		s/\*i/\x{0399}/ig; 	s/i/\x{03B9}/ig;
		s/\*k/\x{039A}/ig; 	s/k/\x{03BA}/ig;
		s/\*l/\x{039B}/ig; 	s/l/\x{03BB}/ig;
		s/\*m/\x{039C}/ig; 	s/m/\x{03BC}/ig;
		s/\*n/\x{039D}/ig; 	s/n/\x{03BD}/ig;
		s/\*c/\x{039E}/ig; 	s/c/\x{03BE}/ig;
		s/\*o/\x{039F}/ig; 	s/o/\x{03BF}/ig;
		s/\*p/\x{03A0}/ig; 	s/p/\x{03C0}/ig;
		s/\*r/\x{03A1}/ig; 	s/r/\x{03C1}/ig;
		s/s\b/\x{03C2}/ig;
		s/\*s/\x{03A3}/ig; 	s/s/\x{03C3}/ig;
		s/\*t/\x{03A4}/ig; 	s/t/\x{03C4}/ig;
		s/\*u/\x{03A5}/ig; 	s/u/\x{03C5}/ig;
		s/\*f/\x{03A6}/ig; 	s/f/\x{03C6}/ig;
		s/\*x/\x{03A7}/ig; 	s/x/\x{03C7}/ig;
		s/\*y/\x{03A8}/ig; 	s/y/\x{03C8}/ig;
		s/\*w/\x{03A9}/ig; 	s/w/\x{03C9}/ig;
	
	}

	return wantarray ? @text : $text[0];
}

1;
