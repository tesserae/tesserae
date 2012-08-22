#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

#
# read_table.pl
#
# select two texts for comparison using the big table
#

use strict;
use warnings;

use CGI qw(:standard);

use Getopt::Long;
use POSIX;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

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

	$file = catfile($fs_tmp, "tesresults-" . $session . ".bin");
}
else {
	
	$file = shift @ARGV;
}


#
# load the file
#

print STDERR "reading $file\n" unless $quiet;

my %match = %{retrieve($file)};

#
# set some parameters
#

my %name;

# source means the alluded-to, older text

$name{source} = $match{META}{SOURCE};

# target means the alluding, newer text

$name{target} = $match{META}{TARGET};

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = $match{META}{UNIT};

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = $match{META}{FEATURE};

# stoplist

my @stoplist = @{$match{META}{STOPLIST}};

# session id

$session = $match{META}{SESSION};

# total number of matches

my $total_matches = $match{META}{TOTAL};

# notes

my $comments = $match{META}{COMMENT};

# now delete the metadata from the match records 

delete $match{META};

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = "$fs_data/common/abbr";
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = "$fs_data/common/lang";
my %lang = %{retrieve($file_lang)};

#
# source and target data
#

my %locus;
my %token;
my %line;

# read texts from database

for my $text (qw/target source/) {

	unless ($quiet) {
	
		print STDERR "reading $text data\n" unless ($quiet);
	}

	$file = catfile($fs_data, 'v3', $lang{$name{$text}}, $name{$text}, $name{$text});

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
	
	my $file_param = catfile($fs_data, "common", "$lang{$name{target}}.syn.cache.param");

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

for my $unit_id_target (sort {$a <=> $b} keys %match) {

	for my $unit_id_source (sort {$a <=> $b} keys %{$match{$unit_id_target}}) {
		
		my %unit_id = (target => $unit_id_target, source => $unit_id_source);
		
		# for each token in the "self" text
		
		for my $token_id_self (keys %{$match{$unit_id_target}{$unit_id_source}{'MARKED_' . uc($self)}}) {

			# create a link to the "other" unit
			
			my %l = 
				(
					unit => $unit_id{$other}, 
					token => []
				);
				
			# and include the specific words from the "other" text
			
			for my $token_id_other (sort keys %{$match{$unit_id_target}{$unit_id_source}{'MARKED_' . uc($other)}}) {
				
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

my $frame = `php -f $fs_html/frame.fulltext.php`;

# insert the table into the template

$frame =~ s/<!--me-->/$name{$self}/g;
$frame =~ s/<!--other-->/$name{$other}/g;

$frame =~ s/<!--fulltext-->/$table/;

# send to browser

print $frame;

