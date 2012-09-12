#! /opt/local/bin/perl5.12

=head1 NAME 

read_bin.pl - Sort and format the results of a Tesserae search.

=head1 SYNOPSIS

B<read_bin.pl> [B<--quiet>] [B<--sort> I<key>] [B<--reverse>] [B<--export> I<mode>] [B<--batch> I<page_size>] [B<--page> I<page_no>] <I<FILE> | B<--session> I<session_id>>

=head1 DESCRIPTION

This script reads the binary results file produced by I<read_table.pl> and presents the results to the user.  It's usually run behind the scenes to create the paged HTML tables seen from the web interface, but it can also be run from the command-line, and can format results as CSV or XML as well as HTML.

It takes a I<FILE> to read as its argument, or alternatively the I<session_id> of a previous web session.  Output is dumped to STDOUT.

Options:

=over

=item --quiet

Don't write progress info to STDERR.

=item B<--sort> target|source|score

Which column to sort the results table by.  B<target> (the default) sorts by location in the target text, B<source>, by location in the source text, and B<score> sorts by the Tesserae-assigned score.

=item B<--reverse>

Reverse the sort order.  For sorting by score this is probably a good idea; otherwise you get the lowest scores first.

=item B<--batch> I<page_size>

For paged results, I<page_size> gives the number of results per page. The default is 100.  If you say B<all> here instead of a number, you'll get all the results on one page.

=item B<--page> I<page_no> 

For paged results, I<page_no> gives the page to display.  The default is 1.

=item B<--export> html|csv|xml

How to format the results.  The default is B<html>.  NB: CSV results are not paged, but will be sorted according to the values of B<--sort> and B<--rev>.  XML results are neither paged nor sorted (actually, they're always sorted by target).

=item B<--session> I<session_id>

When this option is given, the results are read not from a file specified as a command line argument, but rather from the previously created session file in C<tmp/> having id I<session_id>.  This is useful if the results you want to read were generated from the web interface.

=back

=head1 EXAMPLE

% cgi-bin/read_table.pl --export csv results.bin > results.csv

=head1 SEE ALSO

I<cgi-bin/read_table.pl>

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is read_bin.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Neil Coffee, Chris Forstall, James Gawley.

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

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

# format for results

my $export = 'html';

#
# command-line arguments
#

GetOptions( 
	'sort=s'    => \$sort,
	'reverse'   => \$rev,
	'page=i'    => \$page,
	'batch=i'   => \$batch,
	'session=s' => \$session,
	'export=s'  => \$export,
	'quiet'     => \$quiet );

#
# cgi input
#

unless ($no_cgi) {
	
	my $query = new CGI || die "$!";

	$session = $query->param('session')    || die "no session specified from web interface";
	$sort       = $query->param('sort')    || $sort;
	$rev        = $query->param('rev')     || $rev;
	$page       = $query->param('page')    || $page;
	$batch      = $query->param('batch')   || $batch;
	$export     = $query->param('export')  || $export;

	my %h = ('-charset'=>'utf-8', '-type'=>'text/html');
	
	if ($export eq "xml") { $h{'-type'} = "text/xml"; $h{'-attachment'} = "tesresults-$session.xml" }
	if ($export eq "csv") { $h{'-type'} = "text/csv"; $h{'-attachment'} = "tesresults-$session.csv" }
	
	print header(%h);
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

delete $match{META};

# sort the results

my @rec = @{sort_results()};

if ($batch eq 'all') {

	$batch = $total_matches;
	$page  = 1;
}

#
# load texts
#

# abbreviations of canonical citation refs

my $file_abbr = "$fs_data/common/abbr";
my %abbr = %{ retrieve($file_abbr) };

# language of input texts

my $file_lang = "$fs_data/common/lang";
my %lang = %{retrieve($file_lang)};

# read source text

unless ($quiet) {
	
	print STDERR "reading source data\n";
}

my $path_source = "$fs_data/v3/$lang{$source}/$source";

my @token_source   = @{ retrieve( "$path_source/$source.token"    ) };
my @unit_source    = @{ retrieve( "$path_source/$source.${unit}" ) };
my %index_source   = %{ retrieve( "$path_source/$source.index_$feature" ) };

# read target text

unless ($quiet) {

	print STDERR "reading target data\n";
}

my $path_target = "$fs_data/v3/$lang{$target}/$target";

my @token_target   = @{ retrieve( "$path_target/$target.token"    ) };
my @unit_target    = @{ retrieve( "$path_target/$target.${unit}" ) };
my %index_target   = %{ retrieve( "$path_target/$target.index_$feature" ) };


#
# if the featureset is synonyms, get the parameters used
# to create the synonym dictionary for debugging purposes
#

my $max_heads = "NA";
my $min_similarity = "NA";

if ( $feature eq "syn" ) { 

	($max_heads, $min_similarity) = @{ retrieve("$fs_data/common/$lang{$target}.syn.cache.param") };
}

#
# output
#

if ($export eq "html") {

	print_html($page, $batch);	
}
elsif ($export eq "csv") {
	
	print_csv();
}
elsif  ($export eq "xml") {
	
	print_xml();
}


#
# subroutines
#

sub nav_page {
		
	my $html = "<p>$total_matches results";
	
	my $pages = ceil($total_matches/$batch);
	
	#
	# if there's only one page, don't bother
	#
	
	if ($pages > 1) {
				
		$html .= " in $pages pages.</br>\n";
	
		#
		# draw navigation links
		# 
	
		my @left = ();
		my @right = ();
	
		my $back_arrow = "";
		my $forward_arrow = "";
			
		$html .= "Go to page: ";
	
		if ($page > 1) {
		
			$back_arrow .= "<span>";
			$back_arrow .= "<a href=\"$url_cgi/read_multi.pl?session=$session;sort=$sort;rev=$rev;page=1;batch=$batch\"> [first] </a>\n";
			$back_arrow .= "</span>";

			my $p = $page-1;

			$back_arrow .= "<span>";				
			$back_arrow .= "<a href=\"$url_cgi/read_multi.pl?session=$session;sort=$sort;rev=$rev;page=$p;batch=$batch\"> [previous] </a>\n";
			$back_arrow .= "</span>";
		
		
			@left = (($page > 4 ? $page-4 : 1)..$page-1);
		}
	
		if ($page < $pages) {
		
			my $p = $page+1;
		
			$forward_arrow .= "<span>";
			$forward_arrow .= "<a href=\"$url_cgi/read_multi.pl?session=$session;sort=$sort;rev=$rev;page=$p;batch=$batch\"> [next] </a>\n";
			$forward_arrow .= "</span>";

			$forward_arrow .= "<span>";
			$forward_arrow .= "<a href=\"$url_cgi/read_multi.pl?session=$session;sort=$sort;rev=$rev;page=$pages;batch=$batch\"> [last] </a>\n";		       
			$forward_arrow .= "</span>";
		
			@right = ($page+1..($page < $pages-4 ? $page+4 : $pages));
		}
	
		$html .= $back_arrow;
	
		for my $p (@left, $page, @right) {
		
			$html .= "<span>";
		
			if ($page == $p) { 
			
				$html .= " $p ";
			}
			else {
			
				$html .= "<a href=\"$url_cgi/read_multi.pl?session=$session;sort=$sort;rev=$rev;page=$p;batch=$batch\"> $p </a>";
			}	
			
			$html .= "</span>";
		}
	
		$html .= $forward_arrow;
		$html .= "\n";
	}
			
	return $html;
	
}

sub re_sort {
	
	my @sel_rev    = ("", "");
	my %sel_sort   = (target => "", source => "", score => "");
	my %sel_export = (html => "", xml => "", csv => "");
	my %sel_batch  = (50 => '', 100 => '', 200 => '', $total_matches => '');

	$sel_rev[$rev]       = 'selected="selected"';
	$sel_sort{$sort}     = 'selected="selected"';
	$sel_export{$export} = 'selected="selected"';
	$sel_batch{$batch}   = 'selected="selected"';

	my $html=<<END;
	
	<form action="$url_cgi/read_multi.pl" method="post" id="Form1">
		
		<table>
			<tr>
				<td>

			Sort

			<select name="rev">
				<option value="0" $sel_rev[0]>increasing</option>
				<option value="1" $sel_rev[1]>decreasing</option>
			</select>

			by

			<select name="sort">
				<option value="target" $sel_sort{target}>target locus</option>
				<option value="source" $sel_sort{source}>source locus</option>
				<option value="score"  $sel_sort{score}>score</option>
			</select>

			and format as

			<select name="export">
				<option value="html" $sel_export{html}>html</option>
				<option value="csv"  $sel_export{csv}>csv</option>
				<option value="xml"  $sel_export{xml}>xml</option>
			</select>.
			
			</td>
			<td>
				<input type="hidden" name="session" value="$session" />
				<input type="submit" name="submit" value="Change Display" />
			</td>
		</tr>
		<tr>
			<td>
									
			Show

			<select name="batch">
				<option value="50"  $sel_batch{50}>50</option>
				<option value="100" $sel_batch{100}>100</option>
				<option value="200" $sel_batch{200}>200</option>
				<option value="all" $sel_batch{$total_matches}>all</option>
			</select>

			results at a time.
			</td>
		</tr>
	</table>
	</form>

END
	
	return $html;
	
}

sub print_html {
	
	my $first; 
	my $last;
	
	$first = ($page-1) * $batch;
	$last  = $first + $batch - 1;
	
	if ($last > $total_matches) { $last = $total_matches }
	
	my $html = `php -f $fs_html/results.multi.php`;
	
	my ($top, $bottom) = split /<!--results-->/, $html;
	
	$top =~ s/<!--pager-->/&nav_page()/e;
	$top =~ s/<!--sorter-->/&re_sort()/e;
	$top =~ s/<!--session-->/$session/;
	
	print $top;
	
	my $pr = ProgressBar->new($last-$first);

	for my $i ($first..$last) {
		
		$pr->advance();

		my $unit_id_target = $rec[$i]{target};
		my $unit_id_source = $rec[$i]{source};
						
		#
		# print one row of the table
		#
		
		my $score = sprintf("%i", $match{$unit_id_target}{$unit_id_source}{SCORE});
		my %marked_source = %{$match{$unit_id_target}{$unit_id_source}{MARKED_SOURCE}};
		my %marked_target = %{$match{$unit_id_target}{$unit_id_source}{MARKED_TARGET}};

		# format the list of all unique shared words
	
		my $keys = join(", ", @{$match{$unit_id_target}{$unit_id_source}{KEY}});

		# now write the xml record for this match

		print "  <tr>\n";

		# result serial number

		print "    <td>" . sprintf("%i", $i+1) . ".</td>\n";
		print "    <td>\n";
		print "      <table>\n";
		print "        <tr>\n";
		
		# target locus
		
		print "          <td>\n";
		print "            <a href=\"javascript:;\""
		    . " onclick=\"window.open(link='$url_cgi/context2.pl?target=$target;unit=$unit;id=$unit_id_target', "
		    . " 'context', 'width=520,height=240')\">";
		print "$abbr{$target} $unit_target[$unit_id_target]{LOCUS}";
		print "            </a>\n";
		print "          </td>\n";
		
		# target phrase
		
		print "          <td>\n";
		
		for my $token_id_target (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
		
			if (defined $marked_target{$token_id_target}) { print '<span class="matched">' }
			print $token_target[$token_id_target]{DISPLAY};
			if (defined $marked_target{$token_id_target}) { print "</span>" }
		}
		
		print "          </td>\n";
		
		print "        </tr>\n";
		print "      </table>\n";
		print "    </td>\n";
		print "    <td>\n";
		print "      <table>\n";
		print "        <tr>\n";
		
		# source locus
		
		print "          <td>\n";
		print "            <a href=\"javascript:;\""
		    . " onclick=\"window.open(link='$url_cgi/context2.pl?target=$source;unit=$unit;id=$unit_id_source', "
		    . " 'context', 'width=520,height=240')\">";
		print "$abbr{$source} $unit_source[$unit_id_source]{LOCUS}";
		print "            </a>\n";
		print "          </td>\n";
		
		# source phrase
		
		print "          <td>\n";
		
		for my $token_id_source (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
		
			if (defined $marked_source{$token_id_source}) { print '<span class="matched">' }
			print $token_source[$token_id_source]{DISPLAY};
			if (defined $marked_source{$token_id_source}) { print '</span>' }
		}
		
		print "          </td>\n";

		print "        </tr>\n";
		print "      </table>\n";
		print "    </td>\n";
		
		# keywords
		
		print "    <td>$keys</td>\n";

		# score
		
		print "    <td>$score</td>\n";
		
		
		# multi-text results

		print "   <td>";
				
		if (defined $match{$unit_id_target}{$unit_id_source}{MULTI}) {
		
			print format_multi_html($match{$unit_id_target}{$unit_id_source}{MULTI});
		}
		
		print "   </td>";
		
		# finish row
		
		print "  </tr>\n";
	}
	
	$bottom =~ s/<!--session_id-->/$session/;
	$bottom =~ s/<!--source-->/$source/;
	$bottom =~ s/<!--target-->/$target/;
	$bottom =~ s/<!--comments-->/$comments/;
	
	my $stoplist = join(", ", @stoplist);
	
	$bottom =~ s/<!--stoplist-->/$stoplist/;
	
	print $bottom;
}

sub print_csv {
	
	print join (",", 
	
		qw(
			"RESULT"
			"TARGET_LOC"
		   "TARGET_TXT"
			"SOURCE_LOC"
			"SOURCE_TXT"
			"SHARED"
			"SCORE"
			"MARKED_TARGET"
			"MARKED_SOURCE"
			"MULTI"
		)
		) . "\n";

	for my $i (0..$#rec) {

		my $unit_id_target = $rec[$i]{target};
		my $unit_id_source = $rec[$i]{source};
		
		my %marked_source = %{$match{$unit_id_target}{$unit_id_source}{MARKED_SOURCE}};
		my %marked_target = %{$match{$unit_id_target}{$unit_id_source}{MARKED_TARGET}};
		
		#
		# print one row of the table
		#
		
		my $score = sprintf("%i", $match{$unit_id_target}{$unit_id_source}{SCORE});

		# format the list of all unique shared words
	
		my $keys = join(", ", @{$match{$unit_id_target}{$unit_id_source}{KEY}});

		#
		# now prepare the csv record for this match
		#

		my @row;
		
		# result serial number
		
		push @row, $i+1;
		
		# target locus
		
		push @row, "\"$abbr{$target} $unit_target[$unit_id_target]{LOCUS}\"";
		
		# target phrase
		
		my $phrase = "";
				
		for my $token_id_target (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
		
			$phrase .= $token_target[$token_id_target]{DISPLAY};
		}
		
		push @row, "\"$phrase\"";
				
		# source locus
		
		push @row, "\"$abbr{$source} $unit_source[$unit_id_source]{LOCUS}\"";
		
		# source phrase
		
		$phrase = "";
		
		for my $token_id_source (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
		
			$phrase .= $token_source[$token_id_source]{DISPLAY};
		}
				
		push @row, "\"$phrase\"";
		
		# keywords
		
		push @row, "\"$keys\"";

		# score

		push @row, $score;
		
		# additional columns to help excel color code the matching words
		
		# target
		
		my @match_token_index;		
		my $word_count;
		
		for my $token_id (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
		
			if ($token_target[$token_id]{TYPE} eq "WORD") { $word_count++ }
		
			if (defined $marked_target{$token_id}) {
		
				push @match_token_index, $word_count;
			}
		}
		
		push @row, '"' . join(";", @match_token_index) . '"';
		
		# source
		
		@match_token_index = ();
		$word_count = 0;
		
		for my $token_id (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
		
			if ($token_source[$token_id]{TYPE} eq "WORD") { $word_count++ }
		
			if (defined $marked_source{$token_id}) {
		
				push @match_token_index, $word_count;
			}
		}
		
		push @row, '"' . join(";", @match_token_index) . '"';
		
		# multi-text search
		
		my @multi;
		
		if (defined $match{$unit_id_target}{$unit_id_source}{MULTI}) {
		
			for my $other (sort keys %{$match{$unit_id_target}{$unit_id_source}{MULTI}}) {
			
				push @multi, $other . '(' . scalar(@{$match{$unit_id_target}{$unit_id_source}{MULTI}{$other}}) . ')';
			}
		}
		
		push @row, '"' . join("; ", @multi) . '"';
		
		# print row
		
		print join(",", @row) . "\n";
	}
}


sub print_xml {

	#
	# print xml
	#

	# this line should ensure that the xml output is encoded utf-8

	binmode STDOUT, ":utf8";

	# format the stoplist

	my $commonwords = join(", ", @stoplist);

	# add a featureset-specific message

	my %feature_notes = (
	
		word => "Exact matching only.",
		stem => "Stem matching enabled.  Forms whose stem is ambiguous will match all possibilities.",
		syn  => "Stem + synonym matching.  This search is still in development.  Note that stopwords may match on less-common synonyms.  max_heads=$max_heads; min_similarity=$min_similarity"
	
		);

	print STDERR "writing results\n" unless $quiet;

	# draw a progress bar

	my $pr = $quiet ? 0 : ProgressBar->new(scalar(keys %match));

	# print the xml doc header

	print <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<results source="$source" target="$target" unit="$unit" feature="$feature" sessionID="$session" version="3">
	<comments>V3 results. $feature_notes{$feature}</comments>
	<commonwords>$commonwords</commonwords>
END

	# now look at the matches one by one, according to unit id in the target

	for my $unit_id_target (sort {$a <=> $b} keys %match)
	{

		# advance the progress bar

		$pr->advance() unless $quiet;
	
		# look at all the source units where the feature occurs
		# sort in numerical order

		for my $unit_id_source ( sort {$a <=> $b} keys %{$match{$unit_id_target}})
		{

			# get this parallel's score & marked words from the record

			my $score = $match{$unit_id_target}{$unit_id_source}{SCORE};
			my %marked_source = %{$match{$unit_id_target}{$unit_id_source}{MARKED_SOURCE}};
			my %marked_target = %{$match{$unit_id_target}{$unit_id_source}{MARKED_TARGET}};

			# format the list of all unique shared words
		
			my $keypair = join(", ", @{$match{$unit_id_target}{$unit_id_source}{KEY}});

			# now write the xml record for this match

			print "\t<tessdata keypair=\"$keypair\" score=\"$score\">\n";

			print "\t\t<phrase text=\"source\" work=\"$abbr{$source}\" "
					. "unitID=\"$unit_id_source\" "
					. "line=\"$unit_source[$unit_id_source]{LOCUS}\" "
					. "link=\"$url_cgi/context2.pl?target=$source;unit=$unit;id=$unit_id_source\">";

			# here we print the unit

			for my $token_id_source (@{$unit_source[$unit_id_source]{TOKEN_ID}}) {
			
				if (defined $marked_source{$token_id_source}) { print '<span class="matched">' }

				# print the display copy of the token
			
				print $token_source[$token_id_source]{DISPLAY};
			
				# close the tag if necessary
			
				if (defined $marked_source{$token_id_source}) { print '</span>' }
			}

			print "</phrase>\n";
		
			# same as above, for the target now
		
			print "\t\t<phrase text=\"target\" work=\"$abbr{$target}\" "
					. "unitID=\"$unit_id_target\" "
					. "line=\"$unit_target[$unit_id_target]{LOCUS}\" "
					. "link=\"$url_cgi/context2.pl?target=$target;unit=$unit;id=$unit_id_target\">";

			for my $token_id_target (@{$unit_target[$unit_id_target]{TOKEN_ID}}) {
			
				if (defined $marked_target{$token_id_target}) { print '<span class="matched">' }
				print $token_target[$token_id_target]{DISPLAY};
				if (defined $marked_target{$token_id_target}) { print "</span>" }
			}

			print "</phrase>\n";

			print "\t</tessdata>\n";

		}
	}


	# finish off the xml doc

	print "</results>\n";	
}

sub sort_results {
	
	my @rec;
		
	for my $unit_id_target (sort {$a <=> $b} keys %match) {

		for my $unit_id_source (sort {$a <=> $b} keys %{$match{$unit_id_target}}) {
			
			push @rec, {target => $unit_id_target, source => $unit_id_source};
		}
	}
	
	if ($export ne "xml") {
	
		if ($sort eq "source") {
	
			@rec = sort {$$a{source} <=> $$b{source}} @rec;
		}
	
		if ($sort eq "score") {
	
			@rec = sort {$match{$$a{target}}{$$a{source}}{SCORE} <=> $match{$$b{target}}{$$b{source}}{SCORE}} @rec;
		}

		if ($rev) { @rec = reverse @rec };
	}
	
	return \@rec;
}

sub format_multi_html {
	
	my $href = shift;
	
	# this hash has text identifiers as its keys;
	# the values are arrays of unit ids within the text
	
	my %multi = %$href;
		
	my $html = "<table>";
	
	for my $other (sort keys %multi) {

		$html .= "<tr>";
		$html .= "<td>$other</td>";
		$html .= "<td>";
		
		my @a;
						
		for my $unit_id_other (sort {$a <=> $b} keys %{$multi{$other}}) {
						
			my $locus_other   = $multi{$other}{$unit_id_other};

			my $a = "<a href=\"javascript:;\" onclick=\"window.open(link='$url_cgi/context2.pl?target=$other;unit=$unit;id=$unit_id_other',  'context', 'width=520,height=240')\">$locus_other</a>";
			
			push @a, $a;
		}
		
		$html .= join(", ", @a);
		
		$html .= "</td>";
		$html .= "</tr>";
	}
	
	$html .= "</table>\n";
	
	return $html;
}