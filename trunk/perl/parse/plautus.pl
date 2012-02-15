# a script for processing plautus texts

use strict;
use warnings;

use lib '/Users/chris/tesserae/perl'; # PERL_PATH

use TessSystemVars;

use File::Spec::Functions;
use utf8;

binmode STDERR, ":utf8";

# filenames and reference abbreviations for the plays of plautus

my %abbr  = %{ abbr("abbr")  };
my %fname = %{ abbr("fname") };

while (my $filename = shift @ARGV ) {
	
	my $text_key = $filename;
	$text_key =~ s/.*[\/\\]//;
	$text_key =~ s/\.xml//;
	
	print STDERR "reading $filename\n";

	my @line;
	my @number;
		
	# step one: read the TEI file
	
	open (my $fh, "<:utf8", $filename) || die "can't read $filename";

	while (<$fh>) {

		# first process any <l> before the first <lb />
		
		if ( s/(.+?)(?=<lb)// ) {
			
			my $working = $1;
			
			while ($working =~ s/<l\b.*?>(.*?)($|<\/l>)//) {
				
				$line[-1] .= " " . $1;
			}
		}
		
		# next, process each <lb/> and following <l>
			
		while (s/<lb\b(.*?)\/>(.*?)($|<lb)/$3/) { 
			
			my ($tag, $working) = ($1, $2);
			
			push @line, "";
			push @number, "";
			
			if ($tag =~ /n="(.+?)"/) {
				
				$number[-1] = " " . $1;
			}
			
			while ($working =~ s/<l\b.*?>(.*?)($|<\/l>)//) {
				
				$line[-1] .= " " . $1;
			}						
		}
		
		# finally process any remaining <l>
		# presumably on line without an <lb/> 
		
		while (s/<l\b.*?>(.*?)($|<\/l>)//) {
				
			$line[-1] .= " " . $1;
		}
	}
	
	close $fh;
	
	my $path = catfile($fs_text, "la", $fname{$text_key});
	
	print STDERR "writing $path\n";

	open ($fh, ">", $path) || die "can't write to $path";
	
	for (0..$#line) {
		
		$line[$_] =~ s/<abbr.*?<\/abbr>//g;
		$line[$_] =~ s/<gap.*?(\/>|.*?<\/gap>)//g;
		$line[$_] =~ s/<\/?unclear.*?>//g;
		$line[$_] =~ s/<foreign lang="[gG]reek">(.*?)<\/foreign>/&beta_to_uni($1)/eg;

		$line[$_] =~ s/<.+?>//g;
		
		$line[$_] =~ s/&[lg]t;//g;
		$line[$_] =~ s/&mdash;/---/g;
		$line[$_] =~ s/&[lr]dquo;/"/g;
		$line[$_] =~ s/&([aeiou])acute;/$1/ig;
		$line[$_] =~ s/\{\(&amp;.*?&amp;.\)\}//g;
		$line[$_] =~ s/&[a-z]+?;//g;
		
		$line[$_] =~ s/\s+/ /g;
		
		print $fh "<$abbr{$text_key} $number[$_]>\t$line[$_]\n";
		
	}
	
	close $fh;
}

sub abbr {
	
	my $switch = shift;
	
	my %abbr = (
	
		'pl.am_lat' 	=>	'am.',
		'pl.as_lat' 	=>	'as.',
		'pl.aul_lat'	=>	'aul.',
		'pl.bac_lat'	=>	'bacch.',
		'pl.capt_lat'	=>	'capt.',
		'pl.cas_lat'	=>	'cas.',
		'pl.cist_lat'	=>	'cist.',
		'pl.cur_lat'	=>	'curc.',
		'pl.epid_lat'	=>	'ep.',
		'pl.men_lat'	=>	'men.',
		'pl.mer_lat'	=>	'merc.',
		'pl.mil_lat'	=>	'mil.',
		'pl.mos_lat'	=>	'most.',
		'pl.per_lat'	=>	'pers.',
		'pl.poen_lat'	=>	'poen.',
		'pl.ps_lat' 	=>	'ps.',
		'pl.rud_lat'	=>	'rud.',
		'pl.st_lat' 	=>	'stich.',
		'pl.trin_lat'	=>	'trin.',
		'pl.truc_lat'	=>	'truc.'
		);
	
	my %fname = (
	
		'pl.am_lat' 	=>	'amphitruo',
		'pl.as_lat' 	=>	'asinaria',
		'pl.aul_lat'	=>	'aulularia',
		'pl.bac_lat'	=>	'bacchides',
		'pl.capt_lat'	=>	'captivi',
		'pl.cas_lat'	=>	'casina',
		'pl.cist_lat'	=>	'cistellaria',
		'pl.cur_lat'	=>	'curculio',
		'pl.epid_lat'	=>	'epidicus',
		'pl.men_lat'	=>	'menaechmi',
		'pl.mer_lat'	=>	'mercator',
		'pl.mil_lat'	=>	'miles_gloriosus',
		'pl.mos_lat'	=>	'mostellaria',
		'pl.per_lat'	=>	'persa',
		'pl.poen_lat'	=>	'poenulus',
		'pl.ps_lat' 	=>	'pseudolus',
		'pl.rud_lat'	=>	'rudens',
		'pl.st_lat' 	=>	'stichus',
		'pl.trin_lat'	=>	'trinummus',
		'pl.truc_lat'	=>	'truculentus'
		);

	for (values %abbr)	{ 
		$_ = 'pl. ' . $_;
	}
	for (values %fname) { 
		$_ = 'plautus.' . $_ . '.tess';
	}
	
	for ($switch) {
		if (/abbr/)  { return \%abbr }
		if (/fname/) { return \%fname }
		return;
	}
}

sub beta_to_uni
{
	
	my @text = @_;
	
	for (@text)
	{
		
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
