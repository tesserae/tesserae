#!/usr/bin/perl

use lib '/var/www/tesserae/perl';	# PERL_PATH
use TessSystemVars;

use strict;
use warnings;
use Word;
use Phrase;
use Parallel;
use Data::Dumper;
use CGI qw/:standard/;
use Files;
use Storable;

##################################
# begin a new session
# 
##################################

opendir (my $dh, $fs_tmp);
my @session_files = ( grep { /tesresults-[0-9a-f]{8}.xml/ } readdir($dh) );
closedir($dh);

my $session = ( reverse sort @session_files )[0] || "0";

$session =~ s/^.+results-//;
$session =~ s/\.xml//;

$session = sprintf("%08x", hex($session)+1);

my $session_file = "$fs_tmp/tesresults-$session.xml";

open (XML, '>' . $session_file)
	|| die "can't open " . $session_file . ':' . $!;

########################################

my $query = new CGI || die "$!";

# my $session = $query->param('session');
# my $sort = $query->param('sort');
# my $text = $query->param('textOnly');
my $source = $query->param('source') || "";
my $target = $query->param('target') || "";
my $ignore_common= $query->param('ignore_common');
#my $experimental = $query->param('experimental');
my $ignore_low = "yes";
# $ignore_low = $query->param('ignore_low');

$ignore_common = "yes";

my $lang = "la";
my $feature = "stem";

my @stoplist = @{$top{$lang . "_" . $feature}};

my $commonwords = join (" ", @stoplist);

my $file_abbr = "$fs_data/common/abbr";
my %abbr = %{retrieve($file_abbr)};

my $verbose = 0; # 0 == only 5/10; 1 == 0 - 10; 2 == -1 - 10

my $usage = "usage: progname TEXT1 TEXT2\n";

my $debug = 0;
my $no_html = 0;

if ($source eq "") {
	$debug = 1;
	$no_html = 1;
	read_arguments();
}
else {
	print "Content-type: text/html\n\n";
	open STDERR, '>'. $fs_tmp . 'debugging';
	$debug=1;
}

my $comments;

if ($ignore_low eq 'yes') {
	$comments = $comments."exclude low-scoring results; ";
} else {
	$comments = $comments."include low-scoring results; ";
}

if ($ignore_common eq 'yes') {
	$comments = $comments."exclude matches with <a href=\"#\" title=\"abc\">common words</a>; ";
} else {
	$comments = $comments."include matches with <a href=\"#\" title=\"abc\">common words</a>; ";
}

if ($debug >= 1) {
	print STDERR "source: $source\n";
	print STDERR "target: $target\n";
}

my @text;

for ($source, $target)
{
	my $path = "$fs_text/$lang/" .
	 ( /(.*)\.part\./ ? "$1/" : "" );

	print STDERR "path=$path\n";

	push @text, $path.$_.".tess";

}

$text[2] = "$fs_data/v2/preprocessed/" . join('~', sort($source, $target)) . ".preprocessed";
	
if ($debug >= 1) {		
	print STDERR "source label: $source\n";
	print STDERR "target label: $target\n";
	print STDERR "source txt file: $text[0]\n";
	print STDERR "target txt file: $text[1]\n";
	print STDERR "preprocessed file: $text[2]\n";
	print STDERR "session file: $session_file\n";
}



foreach (@text) {
	unless (-r $_)
	{
		die "can't open file ".$_.": ".$!."\n";
	}
}


my @parallels;
my $total_num_matches = 0;

# check if we can open file $text[2] for reading
open (TEST, "<", "$text[2]") || die "can't open file $text[2]: $!\n";
close(TEST);
# read $text[2] and store the result in @parallels. $text[2] can be created by 'preprocess.pl'.
if ( $debug >= 1) {
	print STDERR "parallels are read from file ".$text[2]."\n";
}
@parallels = @{retrieve($text[2])};
#	die Dumper(@parallels);


#my $output = "csv";
#if ($output eq "csv") {
#	my $csvfile = $session_file;
#	$csvfile =~ s/xml/csv/;
#	open (CSV, ">$csvfile")
#	        || die "can't open $csvfile: $!";
#} 

print XML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";

print XML "<results source=\"$source\" target=\"$target\" sessionID=\"".$session."\">\n";
print XML "<comments>$comments</comments>\n";
print XML "<commonwords>$commonwords</commonwords>\n";

my $stylesheet = "$url_css/style.css";
my $redirect = "$url_cgi/get-data.pl?session=$session;sort=target";

unless ($no_html == 1)
{
	print header;
	print <<END;
<html>
        <head>
                <title>Tesserae results</title>
                <link rel="stylesheet" type="text/css" href="$stylesheet" />
                <meta http-equiv="Refresh" content="0; url='$redirect'">
        </head>
        <body>
                <p>
                        Please wait for your results until the page loads completely.
                        <br/>
                        If you are not redirected automatically,
                        <a href="$redirect">click here</a>.
                </p>
        </body>
END
} 
# at this point, array @parallels contains all parallel sentences between two texts that have at least x words in common. 
# print scalar @parallels." parallels found\n";
my $matches = 0;

my $progress_counter = 0;
my $progress_old = 0;
my $progress_timer = time;

foreach (@parallels) {
	$progress_counter++;

#	print " ";
	
	if ($debug==1) {
		my $progress_round = sprintf("%02u",$progress_counter*100/$#parallels);
		if ($progress_round >= $progress_old+5) {
			print STDERR $progress_round ."%\t" . (time - $progress_timer) . " seconds\n";
			$progress_old = $progress_round;
		}
	}
	
	my $score = 0;
	my $parallel = $_;
	bless ($parallel, "Parallel");
	my @words = $parallel->stems_in_common();

	if ($#words < 2) {
		if ($debug == 2) {
			print "Skipping because # of stems is ".$#words."\n";
		}
	} 
	else {
	
		my @words_in_phrase_a = @{$parallel->phrase_a()->wordarray()};
		for (@words_in_phrase_a) {
			my $word = $_;
			bless($word, "Word");
			$word->matched(0);
		}
		my @words_in_phrase_b = @{$parallel->phrase_b()->wordarray()};
		for (@words_in_phrase_b) {
			my $word = $_;
			bless($word, "Word");
			$word->matched(0);
		}

		my @locations_a;
		my @locations_b;
		my $distance_a = 0;
		my $distance_b = 0;

		# score negative if the two words are the same. 
		 if ($words[0] eq $words[1]) {
		 	$score -= 11;
		 }

		foreach (@words) {
			my $parallel_word = $_;
			my $counter_this = 0;
			if ($debug == 2) {print STDERR "matching word ".$parallel_word." in A\n";}
			foreach (@words_in_phrase_a) {
				my $word = $_;
				bless($word, "Word");
				$counter_this++;
				if ($debug == 2) {print STDERR $word->word() . ':';}
				my @stemarray = @{$word->stemarray()};
				foreach (@stemarray) {

					if ($debug == 2) {print STDERR " " . $_;}

					if ($_ eq $parallel_word) {
						if ($word->is_common_word() == 1) {
							$word->matched(1);
						} 
						else {
							$word->matched(2);
						}
						
						if ($debug == 2) {
							print STDERR " match=" . $word->matched() ."\n";
							print STDERR "marking matched word: ".$word->word()." (stem: ".$_.") in verse ".$parallel->phrase_a()->verseno()."\n";
						}					
						last;
					}
				}

				if ($debug == 2) {print STDERR "\n";}
				
				if ($parallel_word eq $word->word()) {
					push @locations_a, $counter_this;
					if ($word->is_common_word() == 1) {
						$word->matched(1);
					} 
					else {
						$word->matched(2);
					}
				
					last;
				} 
			}
			$counter_this = 0;
			if ($debug == 2) { 	print STDERR "debug=$debug\n";	print STDERR "matching word ".$parallel_word." in B\n";}
			foreach (@words_in_phrase_b) 		{
				my $word = $_;
				bless($word, "Word");
				$counter_this++;
				if ($debug == 2) {print STDERR $word->word() . ':';}				
				my @stemarray = @{$word->stemarray()};
				foreach (@stemarray) {
					
					if ($debug == 2) {print STDERR " " . $_;}

					if ($_ eq $parallel_word) {
						if ($word->is_common_word() == 1) {
							$word->matched(1);
						} 
						else {
							$word->matched(2);
						}
						
						if ($debug == 2) {
							print STDERR " match=" . $word->matched() ."\n";
							print STDERR "marking matched word: ".$word->word()." (stem: ".$_.") in verse ".$parallel->phrase_a()->verseno()."\n";
						}					

						last;
					}
				}
				if ($parallel_word eq $word->word()) {
					if ($word->is_common_word() == 1) {
						$word->matched(1);
					} 
					else {
						$word->matched(2);
					}
					push @locations_b, $counter_this;
					last;
				} 
			}
		}
		for (my $i=1; $i < scalar(@locations_a); $i++) {
			$distance_a += $locations_a[$i] - $locations_a[$i-1];
		}
		for (my $i=1; $i < scalar(@locations_b); $i++) {
			$distance_b += $locations_b[$i] - $locations_b[$i-1];
		}


		if ($distance_a == $distance_b) {
			$score += 10;
		} 
		else {

			if (abs($distance_a - $distance_b) <= (2 * scalar @words)) {
				$score += 5;
			}
		}
	
		if ($parallel->phrase_a()->num_matching_words() > 1 && $parallel->phrase_b()->num_matching_words() > 1) {
			if (!($ignore_low eq 'yes' && $score < 4)) {
				my $textoutput  = 0;
				if ($textoutput == 1) {
					if ($score >= 0 || $verbose >= 2) {
						if ($score >= 5 || $verbose >= 1) {

							print "Match $matches\n";
							print "Score: $score\n";

							print "Words in common: ";
							foreach (@words) {
								print $_.", ";
							}
							print "\n";
							#	print "  B: ".$parallel->phrase_a()->phrase()."\n";
							print "parallel->phrase_a()->short_print()\n";
							$parallel->phrase_a()->short_print();
							print "\n";
							print "parallel->phrase_b()->short_print()\n";
							$parallel->phrase_b()->short_print();
							print "\n";
							#	print "  A: ".$parallel->phrase_b()->phrase()."\n";
							print "\n";
						}
						$matches = $matches+1;
					}
				} 
				else {
					my $work_a = $abbr{$source};
					my $work_b = $abbr{$target};

					my $verse_a = $parallel->phrase_a()->verseno();
					my $verse_b = $parallel->phrase_b()->verseno();

					if ($debug==2) {
						print STDERR "locus_a: $work_a $verse_a\n";
						print STDERR "locus_b: $work_b $verse_b\n";
					}

					print XML "<tessdata keypair=\"";
					foreach (@words) {
						print XML escaped_string($_).", ";
					}
					print XML "\" score=\"$score\">\n";
					print XML "<phrase text=\"source\" work=\"$work_a\" ";
					print XML "line=\"".$verse_a."\" ";
					print XML "link=\"$url_cgi/context.pl?source=$source;line=$verse_a\">"
								.$parallel->phrase_a()->short_print2()."</phrase>\n";

					print XML "<phrase text=\"target\" work=\"$work_b\" ";
					print XML "line=\"".$verse_b."\" ";
					print XML "link=\"$url_cgi/context.pl?source=$target;line=$verse_b\">"
								.$parallel->phrase_b()->short_print2()."</phrase>\n";
					print XML "</tessdata>\n";
				}
			}
		}
	}
}

print XML "</results>\n";

unless ($no_html == 1)
{
	print "</html>\n\n";
}

close XML;
exit;

=head2 function: C<compare>

=cut
sub compare {
	my @ws1 = @{$_[0]};
	my @ws2 = @{$_[1]}; 
	if (@ws1 != @ws2) {
		my $num_matches = 0;
#		print "comparing ";
		foreach (@ws1) {
			my $word1 = $_;
			my $matched = 0;
			foreach (@ws2) {
				if ($word1->word() eq $_->word()) {
					$matched ++;
				}
			} 
			if ($matched > 0) {
				$num_matches ++;
			}
#			print $_->word()." ";
		}
		if ($num_matches == scalar(@ws1) || $num_matches == scalar(@ws2)) {
			$total_num_matches++;
			print "wordsets ";
			print_wordset(\@ws1);
			print " and ";
		 	print_wordset(\@ws2);
			print " match; total: ".$total_num_matches."\n";
		} else {
		#	print "wordsets ";
		#	print_wordset(\@ws1);
		#	print " and ";
		 #	print_wordset(\@ws2);
		#	print " don't match\n";
		}
	}

}

=head2 function: C<print_wordset>

=cut
sub print_wordset {
	my @ws = @{$_[0]};
	foreach (@ws) {
		print $_->word()." ";
	}
}


=head2 function: C<compare_phrase>

=cut
sub compare_phrase {
	# compares two 'phrases', ie. arrays of variables of type 'Word'. Returns the number of words that match as a score (0 = no matches)
	my @phrase1 = @{$_[0]};
	my @phrase2 = @{$_[1]};
	my $score = 0;
	
	foreach (@phrase1) {
		my $word1 = $_;
		foreach (@phrase2) {
			my $word2 = $_;
		#	print "comparing ".$word1->word()." -- ".$word2->word()."\n";
			if ($word1->word() eq $word2->word()) {
				$score++;
			}
		}
	}
	return $score;;
}

=head2 function: C<compare_phrase_detail>

=cut
sub compare_phrase_detail {
	my @phrase1 = @{$_[0]};
	my @phrase2 = @{$_[1]};
	my $score = 0;
	
	foreach (@phrase1) {
		my $word1 = $_;
		foreach (@phrase2) {
			my $word2 = $_;
		#	print "comparing ".$word1->word()." -- ".$word2->word()."\n";
			if ($word1->word() eq $word2->word()) {
				if (defined($word1->next) && defined($word2->next) && $word1->next->word() eq $word2->next->word()) {
					$score++;
						if (defined($word1->next->next) && defined($word2->next->next) && $word1->next->next->word() eq $word2->next->next->word()) {
							$score++;
						}
				}
			
			}
		}
	}
	return $score;
}

=head2 function: C<words_in_phrase>

=cut 
sub words_in_phrase {
	my @ws = @{$_[0]};
	my $phraseno = ${$_[1]};
	my @new_ws;
	my @stopwords = ("in", "et", "si", "quis");
	my $include_stopwords = 0;
	foreach (@ws) {
		my $word = $_;
		if ($_->phraseno() == $phraseno) {
			if ($include_stopwords == 1) {
				push @new_ws, $word;
			} else {
				my $is_stopword = 0;
				foreach (@stopwords) {
					my $test = $_;
					
					$test =~ tr/A-Z/a-z/;
					$test =~ tr/a-z//c;
					
					if ($test eq $word) {
						$is_stopword = 1;
						print "stopword found: ".$_."\n";
					}
				}
				if ($is_stopword == 0) {
					push @new_ws, $word;
				}
			}
		}
	}
	return @new_ws;
}

=head2 function: C<escaped_string>

=cut
sub escaped_string {
	my $string = $_[0];
	$string =~ s/#/./;
	return $string;
}
 
=head2 function: C<read_arguments>

Reads cmd-line arguments into global variables. Any argument that is not preceded by '-' is copied into (global) array C<$text>. 

=cut

sub read_arguments {
	
	my @text;

	my $numberoftexts = 0;
	my $numberofflags = 0;
	if ($#ARGV+1 < 2) {
		print STDERR $usage;
		exit;
	}
	for (my $i=0; $i<$#ARGV+1; $i++) {
		if (!(substr($ARGV[$i], 0, 1) eq '-')) {
			$text[$numberoftexts] = $ARGV[$i];
			$numberoftexts++;
		}
	}
	if ($numberoftexts != 2) {
		print STDERR Dumper @text;
		print STDERR "Invalid number of texts specified on the command line ($numberoftexts), should be 2\n";
		print STDERR $usage;
		exit;
	}

	($source, $target) = @text[0,1];
}


