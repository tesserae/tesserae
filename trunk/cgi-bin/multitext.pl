#! /usr/bin/perl

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tess.orig/perl';	# PERL_PATH

#
# multitext.pl
#
# the goal of this script is to check the results of 
# a previous tesserae search against all the other
# texts to see whether the allusions discovered 
# exist elsewhere in the corpus as well.

use strict;
use warnings;

use CGI qw(:standard);

use Getopt::Long;
use POSIX;
use Storable qw(nstore retrieve);
use File::Spec::Functions;

use TessSystemVars;
use EasyProgressBar;

# set autoflush

$|++;

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

# sort algorithm

my $sort = 'target';

# first page of results to display

my $page = 1;

# how many results on a page?

my $batch = 100;

# reverse order ?

my $rev = 0;

# determine file from session id

my $session;

# filter multi results?

my $multi_cutoff = 0;

#
# command-line arguments
#

GetOptions( 
	'sort=s'     => \$sort,
	'page=i'     => \$page,
	'batch=i'    => \$batch,
	'session=s'  => \$session,
	'cutoff=i'   => \$multi_cutoff,
	'quiet'      => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my $query   = new CGI || die "$!";

	$session    = $query->param('session') || die "no session specified from web interface";
	$multi_cutoff = $query->param('mcutoff');

	print header();
	
	print <<END;
	
<html>
   <head>
		<title>Multi-text search in progress...</title>
		<link rel="stylesheet" type="text/css" href="$url_css/style.css" />
	</head>
	<body>
	   <h2>Multi-text search in progress</h2>	
	
	   <p>Please be patient while your results are checked against the rest of the corpus.<br />This can take a while.</p>
	   <p>When the search is done, a link to your results will appear below.</p>
	
END

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

# source means the alluded-to, older text

my $source = $match{META}{SOURCE};

# target means the alluding, newer text

my $target = $match{META}{TARGET};

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

my $meta_saved = $match{META};

delete $match{META};

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs_data, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = catfile($fs_data, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# read source text

unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $file_source = catfile($fs_data, 'v3', $lang{$source}, $source, $source);

my @token_source   = @{ retrieve("$file_source.token")          };
my @unit_source    = @{ retrieve("$file_source.${unit}")        };
my %index_source   = %{ retrieve("$file_source.index_$feature") };

# read target text

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $file_target = catfile($fs_data, 'v3', $lang{$target}, $target, $target);

my @token_target   = @{ retrieve("$file_target.token")          };
my @unit_target    = @{ retrieve("$file_target.${unit}")        };
my %index_target   = %{ retrieve("$file_target.index_$feature") };

# get the list of all the other texts in the corpus

my @textlist = @{get_textlist($target, $source)};

# search other texts

search_multi(\@textlist);

if ($no_cgi) {

	$file =~ s/\.bin/.multi.bin/;
}

$match{META} = $meta_saved;

nstore \%match, $file;

my $redirect = "$url_cgi/read_multi.pl?session=$session";

print <<END unless ($no_cgi);

	</pre>
	</div>

	<div style=\"padding:10px; width:50%; position:absolute; left:25%; top:12em; background-color:white; color:black;\">
   	<p>
			Your results are done!  <a href="$url_cgi/read_multi.pl?session=$session">Click here</a> to proceed.
		</p>
   </div>

</body>
</html>

END


#
# subroutines
#

sub get_textlist {
	
	my ($target, $source) = @_;
	
	for ($target, $source) { s/\.part\..*// }

	my $directory = catdir($fs_data, 'v3', $lang{$target});

	opendir(DH, $directory);
	
	my @textlist = grep {/^[^.]/ && ! /\.part\./} readdir(DH);
	
	closedir(DH);
	
	@textlist = grep {$_ ne $target && $_ ne $source} @textlist;
	
	return \@textlist;
}

sub search_multi {

	# the list of texts to exclude

	my $aref = shift;
	my @textlist = @$aref;
	
	#
	# first, index the matches by the key pairs
	# on which they matched
	#
		
	my %index_keypair;
	my %keys_to_look_for;
	
	print STDERR "parsing the initial search\n" unless $quiet;
	
	my $pr = ProgressBar->new(scalar(keys %match), $quiet);
	
	for my $unit_id_target (keys %match) {
	
		$pr->advance();
		
		for my $unit_id_source (keys %{$match{$unit_id_target}}) {
					
			# the keys on which this parallel was made

			my @keys = @{$match{$unit_id_target}{$unit_id_source}{KEY}};
			
			# arrange the keys into pairs - any one of these in another
			# text constitutes a match
			
			my %pair;
			
			for my $key1 (@keys) {
							
				for my $key2 (@keys) {
				
					next if $key1 eq $key2;

					($key1, $key2) = sort($key1, $key2);
					
					$pair{"$key1~$key2"} = 1;
				}
			}
			
			# add this parallel to the index under each pair
			
			for my $keypair (keys %pair) {
			
				push @{$index_keypair{$keypair}}, {
					TARGET => $unit_id_target, 
					SOURCE => $unit_id_source
				};
			}
		}			
	}
		
	print STDERR "multi-searching on " . scalar(@textlist) . " texts.\n" unless $quiet;

	# check all the other texts
		
	for my $i (0..$#textlist) {
			
		my $other = $textlist[$i];
		
		# print status info
		
		unless ($quiet) {
			
			if ($no_cgi) {
		
				print STDERR sprintf("[%i/%i] checking %s\n", $i+1, scalar(@textlist), $other);
			}
			else {
			
				print "<div style=\"padding:10px; width:50%; position:absolute; left:25%; top:12em; background-color:grey; color:black;\">\n<pre>";
			
			
				print sprintf("[%i/%i] checking %s\n", $i+1, scalar(@textlist), $other);
			}
		}

		my $file = catfile($fs_data, 'v3', $lang{$target}, $other, $other);
		
		my %index_other = %{ retrieve("$file.multi_${unit}_${feature}") };
		my @unit_other  = @{ retrieve($file . '.' . $unit) };

		# check their keypair indices 

		for my $keypair (keys %index_keypair) {
			
			next unless defined $index_other{$keypair};
			
			for (@{$index_keypair{$keypair}}) {

				for my $unit_id_other (keys %{$index_other{$keypair}}) {

					my $unit_id_target = $$_{TARGET};
					my $unit_id_source = $$_{SOURCE};

					my $score_other = $index_other{$keypair}{$unit_id_other};

					next if $score_other < $multi_cutoff;

					$match{$unit_id_target}{$unit_id_source}{MULTI}{$other}{$unit_id_other} = {
					   LOCUS => $unit_other[$unit_id_other]{LOCUS},
					   SCORE => $score_other
					};
				}
			}
		}
				
		unless($no_cgi) {
		
			print "</pre></div>\n";
		}
	}
}

#
# test version of html progress bar
#

package HTMLBar;
	
sub new {
	my $self = {};
	
	shift;
	
	my $terminus = shift || die "HTMLBar->new() called with no final value";
	
	$self->{END} = $terminus;
	
	$self->{COUNT} = 0;
	$self->{PROGRESS} = 0;
	
	bless($self);
	
	print "0%";
	
	print " "x44;
	
	print "100%\n";
	
	return $self;
}

sub advance {

	my $self = shift;
	
	my $incr = shift;
	
	if (defined $incr)	{ $self->{COUNT} += $incr }
	else			   	   { $self->{COUNT} ++       }
	
	if ($self->{COUNT}/$self->{END} > $self->{PROGRESS} + .02) {

		my $old_bars = POSIX::floor($self->{PROGRESS} * 50);
	
		$self->{PROGRESS} = $self->{COUNT} / $self->{END};
	
		my $new_bars = POSIX::floor($self->{PROGRESS} * 50);
		
		if ($new_bars > $old_bars) {
		
			print "=" x ($new_bars - $old_bars);
		}
	}	
}

sub finish {

	my $self = shift;
	
	print "\n";
}

sub progress {
	
	my $self = shift;
	
	return $self->{COUNT};
}

sub terminus {

	my $self = shift;
	
	return $self->{END};
}
