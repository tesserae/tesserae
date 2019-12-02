#!/usr/bin/env perl

=head1 NAME

xml-structure-guided - supervised extraction of text from TEI docs

=head1 SYNOPSIS

xml-structure-guided.pl [options] TEXT [TEXT [...]]

=head1 DESCRIPTION

This script is just a bunch of hacks we've used over the years to try to get
Tesserae compatible texts out of Perseus (and related format) XML documents.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<TEXT>

Document(s) to parse, in TEI XML format.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0. The contents of this file are
subject to the University at Buffalo Public License Version 1.0 (the
"License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is xml-structure-guided.pl.

The Initial Developer of the Original Code is Research Foundation of State
University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research
Foundation of State University of New York, on behalf of University at Buffalo.
All Rights Reserved.

Contributor(s): Chris Forstall <cforstall@gmail.com>, James Gawley, Caitlin
Diddams

Alternatively, the contents of this file may be used under the terms of either
the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General
Public License Version 2.1 (the "LGPL"), in which case the provisions of the
GPL or the LGPL are applicable instead of those above. If you wish to allow use
of your version of this file only under the terms of either the GPL or the
LGPL, and not to allow others to use your version of this file under the terms
of the UBPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL or the
LGPL. If you do not delete the provisions above, a recipient may use your
version of this file under the terms of any one of the UBPL, the GPL or the
LGPL.

=cut

use Getopt::Long;
use POD::Usage;

use Term::UI;
use Term::ReadLine;
use XML::LibXML;
use Data::Dumper;

binmode STDOUT, ":utf8";


# command-line options
my $quiet;
my $help;
my $beta_input;
my $rootname;
my $teins;

GetOptions(
  "quiet" => \$quiet,
  "betacode" => \$beta_input,
  "help" => \$help
);

# print usage if user needs help
if ($help) { pod2usage(1) }


#
# set up terminal interface
#

my $term = Term::ReadLine->new('myterm');

#
# read the list of files from command line
#

my @files = @ARGV;

print STDERR "Checking " . scalar(@files) . " files\n";

#
# parse each file
#

for my $f (0..$#files) {
	
	#
	# step 1: parse the file
	#

	print STDERR "Reading " . ($f+1) . "/" . scalar(@files) . " $files[$f]...";	
  my $doc = XML::LibXML->load_xml(location=>$files[$f]);
	print STDERR "\n";

  # get the name of the root element
  #   - i.e. determine whether it's <TEI> or <TEI.2>
  
  $rootname = $rootname || $doc->documentElement->nodeName;
  
  print STDERR "Root is $rootname\n";  
  unless ($rootname =~ /^TEI(?:\.2)?$/) {
    print STDERR "This doesn't look like the TEI we're expecting\n";
  }
  
  # get the namespace of the root element
  #  - assume this is the namespace for all the nodes we care about
  
  $teins = $teins || $doc->documentElement->namespaceURI;
  
  # assign this namespace to a prefix in an xpath context,
  #  then use this context instead of $doc for the rest of the script
  #  See perldoc XML::LibXML::Node under "findnodes"
  
  my $xpc = XML::LibXML::XPathContext->new;
  $xpc->registerNs("tei", $teins);
  
  #
  # look for work titles in the document header
  #  - sometimes there are multiple works in a single file
  
  print STDERR "Looking for work titles...";
  
	my @title = search_titles($doc, $xpc, $rootname);
  
  if (@title) {
    print STDERR "found " . scalar(@title) . ":\n";
    for (@title) { print "\t$_\n" }
    print STDERR "\n";

  } else {
    print "found none.\n"
  }
	
	#
	# step 2: the parsing is done, now we can search
	#         the structure of the xml document
	#
	
	my @struct = @{getStruct($doc, $xpc)};
  if (@struct) {
    print STDERR "Found structures: " . join(" ", @struct) . "\n";
  }
	
	#
	# step 3: get all the texts in this doc
	#
	
	my @text = $xpc->findnodes("//tei:text[not(tei:text)]", $doc);
	if (@text) {
	  print STDERR "Found " . scalar(@text) . " text elements\n";
	} else {
	  die "Found no text elements!";
	}
  
	#
	# process each text
	#
	
	for my $t (0..$#text) {

		my $text = $text[$t];

		#
		# identify the text
		#

		print STDERR sprintf("Now processing file %i, text %i\n", $f + 1, $t + 1);
		
    # spit out attributes
		for my $a ($text->findnodes("attribute::*")) {
      print STDERR sprintf("\t%s = %s\n", $a->nodeName, $a->nodeValue)
		}
		
		my $text_name = $term->get_reply(
			prompt  => 'Enter an abbreviation for this text?',
			default => 'auth. work.');
		
		#
		# Use one of the structures found in the header to guess which
		# TEI elements denote structural elements.
		#
				
		print STDERR "\n\n";
		
		print STDERR "Looking for predefined structure to start from.\n";
		print STDERR "You can edit this structure by hand later.\n";
		
		my $presumed = $term->get_reply(
				prompt   => 'Your choice?',
				choices  => [ uniq(@struct), 'none of these' ],
				print_me => 'Available structures:',
				default  => (defined $struct[$t] ? $struct[$t] : 'none of these'));
				
		# @div holds structural units
		
		my @div;
		
		if ($presumed ne 'none of these') { 

			my @names = split('\.', $presumed);
			
			for (@names) { 
			
				push @div, {name => $_, elem => '?'}
			}
		}
				
		#
		# count all TEI elements in this <text>
		#
		
		my %count;
		
		for my $elem ($text->findnodes("descendant::*")) {
		
			my $name = $elem->localname;
			
			# for milestone nodes note the type/unit attribute,
			# since they may represent diverse hierarchical levels

			if ($name eq 'milestone') {
			
				$name .= "[unit=" . $elem->getAttribute("unit") . "]";
			}

			# divn nodes are even worse: if the type is "textpart"
      # then you have to check the subtype attribute
      
			if ($name =~ /^div\d?/) {
        
        my $div_type = $elem->getAttribute("type");
        my $suffix = "type=$div_type";
			  
        if ($div_type eq "textpart") {
          my $subtype = $elem->getAttribute("subtype");
          if ($subtype) {
            $suffix = "subtype=$subtype";
          }
        }
				$name .= "[$suffix]";
			}
		
			$count{$name}++;
		}
		
		#
		# now we have a list of all the different
		# kinds of elements that occur.
		#
		# do two guessing tasks:
		# (1) guess which are to be assigned to structural units
		# (2) guess which are to be deleted
		#
		
		my @omit_candidates = qw/note head gap/;

		# how much space to allow in the table

		my $maxname = 0;
		my $maxcount = 0;

		# %omit holds elements to be removed before parsing
		
		my %omit;		
		
		# look at all the elements in turn

		for my $elem (keys %count) {
		
			# adjust the length
		
			$maxname  = length($elem) if length($elem) > $maxname;
			$maxcount = length($count{$elem}) if length($count{$elem}) > $maxcount;
			
			# test whether they match a structural unit's name
			
			for my $i (0..$#div) {
			
				my $name = $div[$i]{name};
			
				if (($elem =~ /$name/i) or
					(lc($name) eq 'line' and $elem eq 'l') or
					(lc($name) eq 'line' and $elem eq 'lb')) {
				
					$div[$i]{elem} = $elem;
				}
			}
			
			# test whether they match deletion candidates
			
			$omit{$elem} = (grep { /^$elem$/i } @omit_candidates) ? 1 : 0;			
		}
		
		#
		# assign structural units to elements
		#
		
		print STDERR "\n\n";
			
		print STDERR "these are all the TEI elements in your text:\n";
		
		my @elem = (sort keys %count);
	
		print STDERR sprintf("\t%-${maxcount}s %-${maxname}s\n", "count", "name");
	
		for (@elem) {
		
			print STDERR sprintf("\t%-${maxcount}s %-${maxname}s\n", $count{$_}, $_);
		}
		
		print STDERR "\n\n";
		
		print STDERR "here we will assign TEI elements to units of text structure.\n";
				
		while (1) {
		
			my $message = "Current assignment:\n";
		
			for my $i (0..$#div) {
						
				$message .= sprintf("\t%i. %s -> %s\n", $i+1, $div[$i]{name}, ($div[$i]{elem} || "?"));
			}
			
			$message .= "Your options:\n";
			
			my $default = 'finished';
			
			if ($#div < 0) { 
			
				$default = 'add a level';
			}
			else {
			
				for (@div) {
				
					if ($$_{elem} eq '?') {
						
						$default = 'change an assignment';
					}
				}
			}
			
			my $opt = $term->get_reply( 
				prompt   => 'Your choice?',
				choices  => ['change an assignment', 'add a level', 'delete a level', 'finished'],
				default  => $default,
				print_me => $message);
								
			if ($opt =~ /change/i) {

				@div = @{change_assignment(\@div, \@elem)};			
			}
			elsif ($opt =~ /add/i) {
				
				@div = @{add_level(\@div)};				
			}
			elsif ($opt =~ /delete/i) {

				@div = @{del_level(\@div)};
			}
			else {
				last;
			}
		}
    
    #
    # resolve <choice> decisions
    #
    
    resolve_choices($doc, $xpc);
		
		#
		# choose elements to omit
		#

		print STDERR "\n\n";

		my @omit = @{omit_dialog(\%omit, \@elem)};
				
		# delete them
				
		for my $elem_type (@omit) {
		
			my @nodes = $xpc->findnodes("descendant::tei:$elem_type", $text);
									
			for my $node (@nodes) {
			
				$node->unbindNode;
			}
		}
	
		#
		# name the output file
		# 

		print STDERR "\n\n";

		my $filename = $term->get_reply(
			prompt  => 'Enter a name for the output file:',
			default => "file$f-$t");

		$filename .= ".tess" unless ($filename =~ /\.tess$/);

		unless (open OFH, ">:utf8", $filename) {
		
			warn "Can't write to $filename.  Aborting this text.\n";
			next;
		}
						
		#
		# process the text
		#
		
		print STDERR "processing text\n";
		
		$text = $text->serialize;

		# delete all newlines, squash whitespace
		
		$text =~ s/\s+/ /sg;
		
		# transliterate greek
		
    if ($beta_input) {
      $text =~ s/<foreign\s+lang="greek".*?>(.*?)<\/foreign>/beta_to_uni($1)/eg;
      $text =~ s/<quote\s+lang="greek".*?>(.*?)<\/quote>/beta_to_uni($1)/eg;
    }
    
		# convert quote tags to quotation marks
		
		$text =~ s/<q\b.*?>/“/g;
		$text =~ s/<\/q>/”/g;
		
		# delete all closing tags
		
		$text =~ s/<\/.*?>//g;
		
		# change assigned unit tags to section boundary strings
		
		for my $i (0..$#div) {
		
			my $elem = $div[$i]{elem};
			my $name = $div[$i]{name};
		
			my $search;
		
			if ($elem =~ s/\[(.+)=(.+)\]//) {
			
				$search = "<$elem\\b([^>]*?$1\\s*=\\s*\"$2\"[^>]*?)\/?>"
			}
			else {
			
				$search = "<$elem\\b(.*?)>"
			}
			
			$text =~ s/$search/TESDIV$i--$1--/g;
		}
				
		# remove all remaining tags
		
		$text =~ s/<.*?>//g;
		
		# convert custom tags back into angle brackets
		
		$text =~ s/TESDIV(\d)--(.*?)--/<div$1 $2>/g;
    		
		# break into chunks on units
		
		$text =~ s/</\n</g;
		
		my @chunk = split(/\n/, $text);
		
		# count chunks
		
		for (0..$#div) {
		
			$div[$_]{count} = 0;
		}
				
		for my $chunk (@chunk) {
		
			if ($chunk =~ s/^<div(\d)(.+?)>//) {
				
				my ($level, $attr) = ($1, $2);
				
				my $n;
				
				if ($attr =~ /\bn\s*=\s*"(.+?)"/) {
				
					$n = $1;
				}
				
				$div[$level]{count} = defined $n ? $n : incr($div[$level]{count});
				
				if ($level < $#div) {
				
					for ($level+1..$#div) {
					
						$div[$_]{count} = 0;
					}
				}
			}
			
			chomp $chunk;
			$chunk =~ s/^\s+//;
			$chunk =~ s/\s+$//;
			
			next unless $chunk =~ /\S/;
         
         if ($beta_input) {
            $chunk = beta_to_uni($chunk);
         }
			
			my $tag = $text_name . " " . join(".", map {$$_{count}} @div);
			
			print OFH "<$tag> $chunk\n";
		}
		
		close OFH;
	}
}

sub getStruct {

	my ($doc, $xpc) = @_;

	# let's look for all unique paths from the document
	# root to its nodes.  this will give us some idea
	# of what kinds of structures exist in the document
	# and, if we count them, in what proportions
	
	my @struct;
	
	print STDERR "Reading document header\n";
	
	# look for <encodingDesc>
		
	for my $refsDecl ($xpc->findnodes("//tei:encodingDesc/tei:refsDecl", $doc)) {

    my @unit;
    
    # there seem to be a diverse set of possible structure declarations;
    #  in each case, there's a series of elements representing successive
    #  hierarchical units of the text, with the human-readable name of
    #  the unit in some attribute of the element
    
    my @structures_to_try = (
      { name => "state", attr => "unit" },
      { name => "step", attr => "refunit" },
      { name => "cRefPattern", attr => "n" }
    );
    
    # try them all until one produces results
    
    for my $s (@structures_to_try) {

      my @nodes = $xpc->findnodes("tei:" . $s->{name}, $refsDecl);
      for (@nodes) {
        push @unit, $_->getAttribute($s->{attr});
      }

      # Not sure this is universal, but CTS version seems list levels
      # from the particular to the general instead of other way around
      if ($refsDecl->getAttribute("n") =~ /^cts$/i) {
        @unit = reverse @unit;
      }
      
      if (@unit) {
        push @struct, join(".", @unit);
        last;
      }
    }    
	}
  
	return \@struct;
}

sub uniq {

	my @array = @_;
		
	my %seen;
	
	my @return;
	
	for (@array) { 
	
		push (@return, $_) unless $seen{$_};

		$seen{$_} = 1;
	}
			
	return @return;
}

sub change_assignment {

	my ($divref, $elemref) = @_;
	
	my @div  = @$divref;
	my @elem = @$elemref;
	
	print STDERR "\n";
	
	if ($#div < 0) {
	
		print STDERR "Can't change assignment; no levels to assign.\n";
		return;
	}
	
	my $default = 1;
	
	for my $i (0..$#div) {
	
		if ($div[$i]{elem} eq '?') {
		
			$default = $i+1;
			last;
		}
	}
	
	my $menu = join("\n", map { "  $_> " . $div[$_-1]{name} } (1..$#div+1));
	
	my $fix = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Change assignment for which division?\n\n" . $menu . "\n",
		allow    => [1..$#div+1],
		default  => $default);
				
	$fix--;
	
	print STDERR "\n";
		
	my $assign = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Choose an element to assign to $div[$fix]{name}\n",
		choices  => [@elem],
		default  => $elem[0]);
		
	$div[$fix]{elem} = $assign;
	
	return \@div;
}

sub add_level {

	my $ref = shift;
	my @div = @$ref;
	
	print STDERR "\n";

	my $menu = join("\n", 
		(map { "  $_> before " . $div[$_-1]{name} } (1..$#div+1)),
		sprintf("  %i> at the end", $#div+2));
		
	my $add = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Where do you want the new level?\n\n" . $menu . "\n",
		allow    => [1..$#div+2],
		default  => $#div+2);
				
	my $name = $term->get_reply(
		prompt  => "What is this level called? ",
		default => sprintf("level%i", $add-1));
				
	$add--;
					
	splice (@div, $add, $#div+1-$add, {name => $name, elem => "?"}, @div[$add..$#div]);
	
	return \@div;
}

sub del_level {

	my $ref = shift;
	my @div = @$ref;
	
	print STDERR "\n";

	my $menu = join("\n", 
	
		map { "  $_> " . $div[$_-1]{name} } (1..$#div+1));
		
	my $del = $term->get_reply(
		prompt   => "Your choice?",
		print_me => "Delete which level?\n\n" . $menu . "\n",
		allow    => [1..$#div+1],
		default  => "$#div");
				
	splice (@div, $del-1, 1);
	
	return \@div;
}

sub omit_dialog {

	my ($omitref, $elemref) = @_;
	my %omit = %$omitref;
	my @elem = @$elemref;
	
	DIALOG: while (1) {

		my $message = "Toggle TEI elements to omit:\n"
					. " starred elements will not be parsed.\n";

		my @choice = $term->get_reply(
			prompt   => "Your choice? ",
			choices  => [(map { ($omit{$_} ? "*" : " ") . $_} @elem ), "finished."],
			default  => "finished.",
			multi    => 1,
			print_me => $message);
			
		for my $choice (@choice) {
	
			last DIALOG if $choice eq "finished.";
	
			substr($choice, 0, 1, "");
				
			$omit{$choice} = ! $omit{$choice};		
		}
	}
	
	my @omit = grep { $omit{$_} } keys %omit;
	
	return \@omit;
}

sub beta_to_uni {
	
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

#
# incr: intelligently increment a line number
#
#       if n is numeric, add one
#       if n has mixed alpha-numeric parts, 
#         try to figure out what's going on
#
#       NB this is only run where no number 
#         has explicitly been given for the 
#         current line; so the editor thought
#         the number was easily deduced from
#         the previous one.

sub incr {

	my $n = shift;
		
	if ($n =~ /(\D*)(\d+)(\D*)?$/i) {
	
		my $pref = defined $1 ? $1 : "";
		my $n    = $2;
		my $suff = defined $3 ? $3 : "";
	
		return $pref . ($2 + 1);
	}
	else {
	
		return $n . "-1";
	}
}


sub search_titles {
  # look for titles -- sometimes more than one per XML file ?
  
  my ($doc, $xpc, $rootname) = @_;
  my @title;
  
  my $xpath = join("/", "",
    map {"tei:" . $_} (
      $rootname, "teiHeader", "fileDesc", "titleStmt", "title"
    )
  );
  
  for my $node ($xpc->findnodes($xpath, $doc)) {

    my $title = $node->textContent;
    if ($title) {
      push @title, $title;
    }
  }
	
  return @title;
}

sub resolve_choices {
  # get user to choose between <sic> and <corr> in <choice> tags.
  
  my ($doc, $xpc) = @_;
  my @choice = $xpc->findnodes("//tei:choice", $doc);
  
  for my $choice (@choice) {
    my $sic = $xpc->findnodes("tei:sic", $choice)->shift;
    my @corr = $xpc->findnodes("tei:corr", $choice);
    
    if (defined $sic and scalar @corr > 0) {
      $sic->unbindNode;
      if (scalar(@corr) > 1) {
        for (@corr[1..$#corr]) {
          $_->unbindNode;
        }
      }
    }
  }
}