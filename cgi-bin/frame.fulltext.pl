#! /opt/local/bin/perl5.12

#
# read_table.pl
#
# select two texts for comparison using the big table
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

use CGI qw(:standard);
use POSIX;
use Storable qw(nstore retrieve);

# allow unicode output

binmode STDOUT, ":utf8";

# is the program being run from the web or
# from the command line?

my $query = CGI->new() || die "$!";

my $no_cgi = defined($query->request_method()) ? 0 : 1;

#
# command-line options
#

# print debugging messages to stderr?

my $quiet = 0;

# determine file from session id

my $session;
my $side;

#
# command-line arguments
#

GetOptions( 
	'session=s' => \$session,
	'side=s'    => \$side,
	'quiet'     => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	print header();

	my $query = new CGI || die "$!";

	$session = $query->param('session')    || die "no session specified from web interface";
	$side = $query->param('side') || 'left';
}

my $file;

if (defined $session) {

	$file = catdir($fs{tmp}, "tesresults-" . $session);
}
else {
	
	$file = shift @ARGV;
}


#
# load the file
#

print STDERR "reading $file\n" unless $quiet;

my %match;

$match{target} = retrieve(catfile($file, "match.target"));
$match{source} = retrieve(catfile($file, "match.source"));

my %meta  = %{retrieve(catfile($file, "match.meta"))};
my %score = %{retrieve(catfile($file, "match.score"))};

#
# set some parameters
#

my %name;

# source means the alluded-to, older text

$name{source} = $meta{SOURCE};

# target means the alluding, newer text

$name{target} = $meta{TARGET};

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = $meta{UNIT};

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = $meta{FEATURE};

# stoplist

my @stoplist = @{$meta{STOPLIST}};

# stoplist basis

my $stoplist_basis = $meta{STBASIS};

# max distance

my $max_dist = $meta{DIST};

# distance metric

my $distance_metric = $meta{DIBASIS};

# low-score cutoff

my $cutoff = $meta{CUTOFF};

# score team filter state

my $filter = $meta{FILTER};

# session id

$session = $meta{SESSION};

# total number of matches

my $total_matches = $meta{TOTAL};

# notes

my $comments = $meta{COMMENT};


#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

#
# source and target data
#

my %locus;
my %token;
my %line;

# read texts from database

for my $text (qw/target source/) {

	if ($no_cgi) {
	
		print STDERR "reading $text data\n" unless ($quiet);
	}

	$file = catfile($fs{data}, 'v3', $lang{$name{$text}}, $name{$text}, $name{$text});

	@{$token{$text}}   = @{ retrieve( "$file.token") };
	@{$line{$text}}    = @{ retrieve( "$file.line") };
	
	my @unit = @{ retrieve( "$file.$unit" ) };

	for (@unit) {
	
		push @{$locus{$text}}, $$_{LOCUS};
	}
}

#
# if the featureset is synonyms, get the parameters used
# to create the synonym dictionary for debugging purposes
#

my $max_heads = "NA";
my $min_similarity = "NA";

if ( $feature eq "syn" ) {
	
	my $file_param = catfile($fs{data}, "common", "$lang{$name{target}}.syn.cache.param");

	($max_heads, $min_similarity) = @{ retrieve($file_param) };
}

#
# consolidate all marked forms
#

# are we marking the target w/ respect to the source (left side)
# or the source with respect to the target (right side)?

my ($self, $other) = $side eq 'left' ? (qw/target source/) : (qw/source target/);

# this will hold links between tokens in the "self" text
# and units in the "other" text

my %link;

# consider each match of the tesserae file

for my $unit_id_target (keys %score) {

	for my $unit_id_source (keys %{$score{$unit_id_target}}) {
		
		my %unit_id = (target => $unit_id_target, source => $unit_id_source);
		
		# for each token in the "self" text
		
		for my $token_id_self (keys %{$match{$self}{$unit_id_target}{$unit_id_source}}) {

			# create a link to the "other" unit
			
			my %l = 
				(
					unit => $unit_id{$other}, 
					token => []
				);
				
			# and include the specific words from the "other" text
			
			for my $token_id_other (sort keys %{$match{$other}{$unit_id_target}{$unit_id_source}}) {
				
				push @{$l{token}}, $token{$other}[$token_id_other]{DISPLAY};
			}
			
			# add the link to the record for this token
			
			push @{$link{$token_id_self}}, \%l;
		}
	}
}


#
# display the full text
# 

# create the table with the full text of the poem

my $table;

$table .= "<table class=\"fulltext\">\n";

for my $line_id (0..$#{$line{$self}}) {

	$table .= "<tr>\n";
	$table .= "<td>$line{$self}[$line_id]{LOCUS}</td>\n";
	$table .= "<td>";
	
	for my $token_id (@{$line{$self}[$line_id]{TOKEN_ID}}) {
	
		if (defined $link{$token_id}) {
			
			my @links;
			
			for my $l (@{$link{$token_id}}) {
			
				my $link_text = $locus{$other}[$l->{unit}];
				
				$link_text .= " " . join(",", @{$l->{token}});
				
				push @links, $link_text;
			}
			
			my $links = join("\n", @links);
			
			$table .= "<span class=\"matched\" title=\"$links\">";
		}
		
		$table .= $token{$self}[$token_id]{DISPLAY};
		
		if (defined $link{$token_id}) {
			
			$table .= "</span>";
		}
	}
	
	$table .= "</td>\n";
	$table .= "</tr>\n";
}

$table .= "</table>\n";

# load the template

my $frame = `php -f $fs{html}/frame.fulltext.php`;

# insert the table into the template

$frame =~ s/<!--me-->/$name{$self}/g;
$frame =~ s/<!--other-->/$name{$other}/g;

$frame =~ s/<!--fulltext-->/$table/;

# send to browser

print $frame;

