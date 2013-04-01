use strict;
use warnings;

#
# Read configuration file
#

# variables set from config

my %fs;
my %url;
my $lib;

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;

# read config before executing anything else

BEGIN {

	# look for configuration file
	
	$lib = $Bin;
	
	my $oldlib = $lib;
	
	my $config = catfile($lib, 'tesserae.conf');
		
	until (-s $config) {
					
		$lib = abs_path(catdir($lib, '..'));
		
		if (-d $lib and $lib ne $oldlib) {
		
			$oldlib = $lib;			
			$config = catfile($lib, 'tesserae.conf');
			
			next;
		}
		
		die "can't find tesserae.conf!\n";
	}
	
	# read configuration
		
	my %par;
	
	open (FH, $config) or die "can't open $config: $!";
	
	while (my $line = <FH>) {
	
		chomp $line;
	
		$line =~ s/#.*//;
		
		next unless $line =~ /(\S+)\s*=\s*(\S+)/;
		
		my ($name, $value) = ($1, $2);
			
		$par{$name} = $value;
	}
	
	close FH;
	
	# extract fs and url paths
		
	for my $p (keys %par) {

		if    ($p =~ /^fs_(\S+)/)		{ $fs{$1}  = $par{$p} }
		elsif ($p =~ /^url_(\S+)/)		{ $url{$1} = $par{$p} }
	}
}

# load Tesserae-specific modules

use lib $fs{perl};

use Tesserae;
use EasyProgressBar;

# load additional modules necessary for this script

use Getopt::Long;
use Storable qw(nstore retrieve);
use File::Basename;
use File::Path qw(mkpath rmtree);

# approximate size of samples in characters

my %size = (target => 500, source => 1000);

# check for cmd line options

GetOptions(
	'target=i' => \$size{target},
	'source=i' => \$size{source}
	);

# language database

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# stem dictionary

my %stem;
my $lang;
my $prev_lang = "none";

# global variables hold working data

my @token;
my @phrase;

# read files to process from cmd line args

my @files = @ARGV;

for my $file_in (@files) {
	
	# large files split into parts are kept in their
	# own subdirectories; if an arg has no .tess extension
	# it may be such a directory

	if (-d $file_in) {

		opendir (DH, $file_in);

		my @parts = (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

		push @files, @parts;
					
		closedir (DH);
		
		# move on to the next full text

		next;
	}
	
	my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
	next unless ($suffix eq ".tess");
	
	# check language
	
	$lang = $lang{$name};
	
	# if it's changed, reload the stem dictionary
	
	if ($lang ne $prev_lang) {
	
		my $file_stem = catfile($fs{data}, 'common', "$lang.stem.cache");
		%stem = %{retrieve($file_stem)};
		
		$prev_lang = $lang;
	}
	
	# load text from v3 database
	
	my $base = catfile($fs{data}, 'v3', $lang, $name, $name);

	@token = @{retrieve("$base.token")};
	@phrase = @{retrieve("$base.phrase")}; 
	
	#
	# process each file as both target and source
	#
	
	print STDERR "$name\n";
	
	for my $mode (qw/source target/) {

		print STDERR "$mode:\n";

		my @bounds;
	
		# create/clean output directory

		my $opdir = catfile($fs{data}, 'lsa', $lang, $name, $mode);
		
		rmtree($opdir);
		mkpath($opdir);
						
		# write samples
				
		my $pr = ProgressBar->new(scalar(@phrase));
		
		my $ndigit = length($#phrase);
		
		for my $i (0..$#phrase) {
		
			$pr->advance();
			
			my $opfile = catfile($opdir, sprintf("%0${ndigit}i", $i));
			
			open (FH, ">:utf8", $opfile) || die "can't create $opfile: $!";
			
			my ($sample, $lbound, $rbound) = sample($size{$mode}, $i);
			
			print FH $sample;
			push @bounds, [$lbound, $rbound];
			
			close FH;
		}
		
		my $file_bounds = catfile($fs{data}, 'lsa', $lang{$name}, $name, "bounds.$mode");
		
		nstore \@bounds, $file_bounds;
	}
}

#
# subroutines
#

sub sample {

	my ($smin, $unit_id) = @_;
		
	my @tokens;
	my $size = 0;
	
	for (@{$phrase[$unit_id]{TOKEN_ID}}) {
	
		if ($token[$_]{TYPE} eq "WORD") {
		
			push @tokens, $_;
			$size += length($token[$_]{FORM});
		}
	}
	
	my $lpos = $phrase[$unit_id]{TOKEN_ID}[0];
	my $rpos = $phrase[$unit_id]{TOKEN_ID}[-1];
	
	while (($size < $smin) and ($rpos-$lpos < $#token)) {
		
		ADDL:
		while ($lpos > 0) {
		
			$lpos --;
			
			next ADDL unless $token[$lpos]{TYPE} eq "WORD";
			
			push @tokens, $lpos;
			
			$size += length($token[$lpos]{FORM});
			
			last ADDL;
		}
		
		ADDR:
		while ($rpos < $#token) {
		
			$rpos ++;
			
			next ADDR unless $token[$rpos]{TYPE} eq "WORD";
			
			push @tokens, $rpos;
			
			$size += length($token[$rpos]{FORM});
			
			last ADDR;
		}
	}
	
	my @stems;
	
	for (@tokens) {
	
		push @stems, @{stems($token[$_]{FORM})};
	}
		
	my $sample = join(" ", @stems)  . "\n";
		
	return ($sample, $lpos, $rpos);
}

sub stems {

	my $form = shift;
	
	my @stems;
	
	if (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}
