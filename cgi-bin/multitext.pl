#!/usr/bin/env perl

#
# multitext.pl
#
# the goal of this script is to check the results of 
# a previous tesserae search against all the other
# texts to see whether the allusions discovered 
# exist elsewhere in the corpus as well.

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
use File::Path qw(mkpath rmtree);
use File::Basename;

# optional modules

my $override_parallel = Tesserae::check_mod("Parallel::ForkManager");

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

# a file containing the list of texts to search

my $list = 0;

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
	'list'       => \$list,
	'cutoff=i'   => \$multi_cutoff,
	'parallel=i' => \$max_processes,
	'quiet'      => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my $query   = new CGI || die "$!";

	$session      = $query->param('session') || die "no session specified from web interface";
	$multi_cutoff = $query->param('mcutoff'); 
	@include      = $query->param('include');
	$list         = $query->param('list');

	print header();
	
	my $redirect = "$url{cgi}/read_multi.pl?session=$session";
	
	print <<END;
	
<html>
	<head>
		<title>Multi-text search in progress...</title>
		<link rel="stylesheet" type="text/css" href="$url{css}/style.css" />
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

	$file = catdir($fs{tmp}, "tesresults-" . $session);
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
# add source and target to exclude list
# 

push @exclude, map { s/\.part\..*// } ($target, $source);

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = catfile($fs{data}, 'common', 'abbr');
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = catfile($fs{data}, 'common', 'lang');
my %lang = %{retrieve($file_lang)};

# read source text

unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $file_source = catfile($fs{data}, 'v3', $lang{$source}, $source, $source);

my @token_source   = @{ retrieve("$file_source.token")          };
my @unit_source    = @{ retrieve("$file_source.${unit}")        };
my %index_source   = %{ retrieve("$file_source.index_$feature") };

# read target text

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $file_target = catfile($fs{data}, 'v3', $lang{$target}, $target, $target);

my @token_target   = @{ retrieve("$file_target.token")          };
my @unit_target    = @{ retrieve("$file_target.${unit}")        };
my %index_target   = %{ retrieve("$file_target.index_$feature") };

# get the list of all the other texts in the corpus

my @textlist = @{textlist($target, $source, \@include, \@exclude, $list)};

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
			<a href="$url{cgi}/read_multi.pl?session=$session">Click here</a> to proceed.
	</p>
	</div>
</body>
</html>

END


#
# subroutines
#

sub textlist {
	
	my ($target, $source, $include, $exclude, $list) = @_;
	
	for ($target, $source) { s/[\._]part[\._].*// }

	my $all_texts = Tesserae::get_textlist($lang{$target}, -no_part=>1);
	
	my @textlist;
	
	if ($list) {
	
		@textlist = @{Tesserae::intersection($all_texts, parse_list($file))};
	}
	elsif (@$include) {
	
		@textlist = @{Tesserae::intersection($all_texts, $include)};
	}
	else {
	
		@textlist = @$all_texts;
	}
		
	@textlist = grep {my $test = $_; ! grep {$_ eq $test} @exclude} @textlist;
	
	return \@textlist;
}

sub parse_list {

	my $file = shift;
	my $file_list = catdir($file, '.multi.list');
	
	open (FH, "<:utf8", $file_list) or die "can't open list $file_list: $!";
	
	my @all_texts;
	
	while (my $line = <FH>) {
	
		if ($line =~ /(\S+)/) {
		
			push @all_texts, $1;
		}
	}
	
 	return \@all_texts;
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
			
			my @pairs = @{Tesserae::intersection($target_pairs, $source_pairs)};
			
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

		my $file = catfile($fs{data}, 'v3', $lang{$target}, $other, $other);
		
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

