#! /opt/local/bin/perl5.12

# the line below is designed to be modified by configure.pl

use lib '/Users/chris/Sites/tesserae/perl';	# PERL_PATH

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
use File::Path qw(mkpath rmtree);
use File::Basename;

use TessSystemVars;
use EasyProgressBar;

# optional modules

use if $ancillary{"Parallel::ForkManager"}, "Parallel::ForkManager";

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

# texts to exclude / include

my @exclude = ();
my @include = ();

# number of processes to run in parallel

my $max_processes = 0;

#
# command-line arguments
#

GetOptions( 
	'sort=s'     => \$sort,
	'page=i'     => \$page,
	'batch=i'    => \$batch,
	'session=s'  => \$session,
	'exclude=s'  => \@exclude,
	'include=s'  => \@include,
	'cutoff=i'   => \$multi_cutoff,
	'parallel=i' => \$max_processes,
	'quiet'      => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my $query   = new CGI || die "$!";

	$session    = $query->param('session') || die "no session specified from web interface";
	$multi_cutoff = $query->param('mcutoff'); 
	@include = $query->param('include');

	print header();
	
	my $redirect = "$url_cgi/read_multi.pl?session=$session";
	
	print <<END;
	
<html>
	<head>
		<title>Multi-text search in progress...</title>
		<link rel="stylesheet" type="text/css" href="$url_css/style.css" />
		<meta http-equiv="Refresh" content="0; url='$redirect'">
	</head>
	<body>
		<div class="waiting">
		<h2>Multi-text search in progress</h2>	
	
		<p>Please be patient while your results are checked against the rest of the corpus.<br />This can take a while.</p>
	
END

}

my $file;

if (defined $session) {

	$file = catdir($fs_tmp, "tesresults-" . $session);
}
else {
	
	$file = shift @ARGV;
}


#
# load the file
#

print STDERR "reading $file\n" unless $quiet;

my %match_target = %{retrieve(catfile($file, "match.target"))};
my %match_source = %{retrieve(catfile($file, "match.source"))};
my %score        = %{retrieve(catfile($file, "match.score"))};
my %meta         = %{retrieve(catfile($file, "match.meta"))};

#
# set some parameters
#

# source means the alluded-to, older text

my $source = $meta{SOURCE};

# target means the alluding, newer text

my $target = $meta{TARGET};

# unit means the level at which results are returned: 
# - choice right now is 'phrase' or 'line'

my $unit = $meta{UNIT};

# feature means the feature set compared: 
# - choice is 'word' or 'stem'

my $feature = $meta{FEATURE};

# stoplist

my @stoplist = @{$meta{STOPLIST}};

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

# create a directory for multi search data

my $multi_dir = catdir($file, "multi");

rmtree($multi_dir);
mkpath($multi_dir);

# search other texts

search_multi($multi_dir, \@textlist);

# save metadata

$meta{MTEXTLIST} = \@textlist;
$meta{MCUTOFF} = $multi_cutoff;

nstore \%meta, catfile($file, "match.meta");

print <<END unless ($no_cgi);

   	<p>
			Your results are done!  If you are not redirected automatically, 
			<a href="$url_cgi/read_multi.pl?session=$session">Click here</a> to proceed.
	</p>
	</div>
</body>
</html>

END


#
# subroutines
#

sub get_textlist {
	
	my ($target, $source) = @_[0,1];
	
	for ($target, $source) { s/[\._]part[\._].*// }

	my $directory = catdir($fs_data, 'v3', $lang{$target});

	opendir(DH, $directory);
	
	my @all_texts = grep {/^[^.]/ && ! /[\._]part[\._]/} readdir(DH);
	
	closedir(DH);
	
	if (@include) {
	
		@all_texts = @{TessSystemVars::intersection(\@include, \@all_texts)};
	}
	
	my @textlist;
	
	for my $text (@all_texts) {

      next if $text eq $target;
      next if $text eq $source;

      next if grep { $_ eq $text } @exclude;

      push @textlist, $text;
   	}
	
	return \@textlist;
}

sub search_multi {

	my ($multi_dir, $aref) = @_;

	# the list of texts to check
	
	my @textlist = @$aref;
	
	#
	# first, index the matches by the key pairs
	# on which they matched
	#
		
	my %index_keypair;
	
	my $pr;
	
	if ($no_cgi) {
	
		print STDERR "parsing the initial search\n" unless $quiet;
	
		$pr = ProgressBar->new(scalar(keys %match_target), $quiet);
	}
	else {
	
		print "<p>parsing the intitial search...\n";
		
		$pr = HTMLProgress->new(scalar(keys %match_target));
		
	}
	
	for my $unit_id_target (keys %match_target) {
	
		$pr->advance();
		
		for my $unit_id_source (keys %{$match_target{$unit_id_target}}) {
								
			# arrange the keys into pairs - any one of these in another
			# text constitutes a match
			
			my $target_pairs = unique_keypairs($match_target{$unit_id_target}{$unit_id_source});
			my $source_pairs = unique_keypairs($match_source{$unit_id_target}{$unit_id_source});
			
			my @pairs = @{TessSystemVars::intersection($target_pairs, $source_pairs)};
			
			# add this parallel to the index under each pair
			
			for my $keypair (@pairs) {
			
				push @{$index_keypair{$keypair}}, {
					TARGET => $unit_id_target, 
					SOURCE => $unit_id_source
				};
			}
		}			
	}
	
	#
	# multi search
	#
			
	if ($no_cgi) {
	
		print STDERR "multi-searching on " . scalar(@textlist) . " texts.\n" unless $quiet;
	}
	else {
	
		print "<p>cross-referencing against " . scalar(@textlist) . " texts...</p>\n";
	}


	# check all the other texts
		
	for my $i (0..$#textlist) {
				
		my $other = $textlist[$i];
		
		# print status info
			
		if ($no_cgi) {
		
			print STDERR sprintf("[%i/%i] checking %s\n", $i+1, scalar(@textlist), $other) unless $quiet;
			
		}
		else {
			
			print "<div style=\"position: absolute; top:200px; height:200px; left:20%; width:60%; background-color:white\">\n";        
			
			print sprintf("[%i/%i] checking %s\n", $i+1, scalar(@textlist), $other);
		}

		my $file = catfile($fs_data, 'v3', $lang{$target}, $other, $other);
		
		my %index_other = %{ retrieve("$file.multi_${unit}_${feature}") };
		my @unit_other  = @{ retrieve("$file.$unit") };

		# this holds results for the other text,
		# keyed to the target-source parallel
		
		my %multi;
				
		# check their keypair indices 

		my $pr;
		
		if ($no_cgi) { $pr = ProgressBar->new(scalar(keys %index_keypair), $quiet) }
		else         { $pr = HTMLProgress->new(scalar(keys %index_keypair)) }

		for my $keypair (keys %index_keypair) {
		
			$pr->advance();
					
			next unless defined $index_other{$keypair};
			
			for (@{$index_keypair{$keypair}}) {

				for my $unit_id_other (keys %{$index_other{$keypair}}) {

					my $unit_id_target = $$_{TARGET};
					my $unit_id_source = $$_{SOURCE};

					my $score_other = $index_other{$keypair}{$unit_id_other};

					next if $score_other < $multi_cutoff;

					$multi{$unit_id_target}{$unit_id_source}{$unit_id_other} = {
					   LOCUS => $unit_other[$unit_id_other]{LOCUS},
					   SCORE => $score_other
					};
				}
			} 			
		}
						
		my $file_out = catfile($multi_dir, $other);
		
		nstore \%multi, $file_out;
		
		print "</div>\n" unless $no_cgi;    
	}	     
}                    


sub unique_keypairs {

	my $ref = shift;
	
	my %unit = %$ref;
	
	my @id = keys %unit;
	
	my %pair;
	
	for my $i (0..$#id-1) {
	
		my $id1 = $id[$i];
	
		for my $j ($i+1..$#id) {
		
			my $id2 = $id[$j];
			
			for my $key1 (keys %{$unit{$id1}}) {
			
				for my $key2 (keys %{$unit{$id2}}) {
				
					$pair{join("~", sort($key1, $key2))} = 1;
				}
			}
		}
	}
	
	return [keys %pair];
}

