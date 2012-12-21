
use strict;
use warnings;

use XML::LibXML;
use utf8;

$|++;

binmode STDOUT, ":utf8";

#
# read the list of files from command line
#

my @files = @ARGV;

print STDERR "checking " . scalar(@files) . " files\n";

#
# parse each file
#

for my $i (0..$#files) {
	
	#
	# step 1: parse the file
	#
	
	# create a new parser object
		
	my $parser = XML::LibXML->new();
	
	# open the file
	
	open (my $fh, "<", $files[$i])	|| die "can't open $files[$i]: $!";

	print STDERR "reading " . ($i+1) . "/" . scalar(@files) . " $files[$i]...";

	# this line is where the whole file is read 
	# and turned into an XML::LibXML object.
	# from now on we're done with the original
	# file and we'll work with $doc
	#
	# unfortunately, i think this will only work if you
	# have internet access, because the documents use
	# a remote DTD for validation

	my $doc = $parser->parse_fh( $fh );

	# close the file

	close ($fh);
	
	print STDERR "done\n";
	
	#
	# step 2: the parsing is done, now we can search
	#         the structure of the xml document
	#
	
	my @struct = @{getStruct($doc)};
	
	#
	# step 3: get all the texts in this doc
	#
	
	my @text = $doc->findnodes("//text[not(text)]");
	
	if ($#text != $#struct) {
	
		print STDERR "found " . ($#text+1). " texts and " . ($#struct+1) . " structures definitions\n";
	}
	
	#
	# process each text
	#
	
	for my $i (0..$#text) {

		my $text = $text[$i];

		#
		# identify the text
		#

		print STDERR "text $i.\t";
		
		my @a = $text->findnodes("attribute::*");
		
		for (@a) {
		
			$_ = $_->nodeName . "=" . $_->nodeValue;
		}
		
		print STDERR join(" ", @a) . "\n";
		
		my $text_name = getInput("Enter an identifier (e.g. \"Auth. Work\") for this text [default \"ABBR\"]?", 'ABBR');
		
		#
		# Use one of the structures found in the header to guess which
		# TEI elements denote structural elements.
		#
		
		my $select;
		
		if (defined $struct[$i]) {
		
			print STDERR "This is our best guess for the structure of the file:\n";
			print STDERR "\t" . join(".", @{$struct[$i]{unit}}) . "\n";
			
			$select = $i if (getInput("Does this look right [Y/n]?", 'y'));
		}
		
		unless (defined $select) {
		
			print STDERR "Use one of these structures instead?\n";
			print STDERR "You can edit the structure by hand on the next screen.\n";
			
			for (0..$#struct) {
			
				print STDERR "\t$_ " . join(".", @{$struct[$_]{unit}}) . "\n";
			}
		
			$select = getInput("Choose by number or hit return for none of these.", 'none');
		}
		
		print "\n\n";
		
		#
		# count all TEI elements in this <text>
		#
		
		my %count;
		
		for my $elem ($text->findnodes("descendant::*")) {
		
			my $name = $elem->nodeName;
			
			# for divn and milestone nodes,
			# note the type/unit attribute,
			# since they may occur at multiple
			# hierarchical levels
			
			if ($name =~ /div/) {
			
				$name .= "[type=" . $elem->getAttribute("type") . "]";
			}
			
			if ($name eq 'milestone') {
			
				$name .= "[unit=" . $elem->getAttribute("unit") . "]";
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
		
		my @deletion_candidates = qw/note head/;

		# how much space to allow in the table

		my $maxlen = 0;

		# @delete holds elements to be deleted
		
		my @delete;		
		
		# @div holds structural units
		
		my @div;
		
		# look at all the elements in turn

		for my $elem (keys %count) {
		
			# adjust the length
		
			$maxlen = length($elem) if length($elem) > $maxlen;
			
			# test whether they match a structural unit's name
			
			for my $i (0..$#{$struct[$select]{unit}}) {
			
				my $name = $struct[$select]{unit}[$i];
			
				if (($elem =~ /$name/i) or
					(lc($name) eq 'line' and $elem eq 'l')) {
				
					$div[$i]{elem} = $elem;
					$div[$i]{name} = $struct[$select]{unit}[$i];
				}
			}
			
			# test whether they match deletion candidates
			
			for (@deletion_candidates) {
		
				if (lc($elem) eq lc($_)) { push @delete, $elem }
			}
		}
		
		#
		# assign structural units to elements
		#
		
		print STDERR "here we will assign TEI elements to units of text structure.\n";
				
		while (1) {
		
			print STDERR "\n";
		
			print STDERR "this is a list of all elements in text $i:\n";
			
			my @elem = (sort keys %count);
	
			print STDERR sprintf("\t%-4s%-${maxlen}s %s\n", " ", "element", "count");
	
			for my $i (0..$#elem) {
			
				my $alpha = chr(97+$i);
			
				print STDERR sprintf("\t%-4s%-${maxlen}s %i\n", "($alpha)", $elem[$i], $count{$elem[$i]});
			}
		
			print STDERR "\n";
		
			print STDERR "proposed structure and assigned elements:\n";
			
			for my $i (0..$#div) {
						
				print STDERR sprintf("\t%i. %s -> %s\n", $i+1, $div[$i]{name}, ($div[$i]{elem} || "?"));
			}
			
			print STDERR "Your options:\n";
			print STDERR "\t[c]hange an assignment\n";
			print STDERR "\t[a]dd a structural level\n";
			print STDERR "\t[d]elete a structural level\n";
		
			my $opt = getInput('Choose from the above, or just press [return] to finish', 'f');
				
			if ($opt =~ /c/i) {
			
				print STDERR "\n";
				
				my $fix = -1;
				
				until ($fix >=0 and $fix <= $#div) {
				
					$fix = getInput("Change assignment for which level [1.." . ($#div+1) . "]?");
					$fix--;
				}
							
				print STDERR "Choose an element to assign to $div[$fix]{name}\n";
				
				my $assign = -1;
				
				until ($assign <= $#elem and $assign >= 0) {
				 
					$assign = getInput('Choose by letter (a-' . chr(97+$#elem) . ') from the list of elements above:');
					
					$assign = ord($assign)-97;
				}
				
				$div[$fix]{elem} = $elem[$assign];
			}
			elsif ($opt =~ /a/i) {
			
				my $add = 0;
			
				if ($#div >= 0) {
				
					print STDERR "Where do you want the new level?\n";
					
					for (0..$#div) {
					
						print STDERR "\t[" . ($_+1) . "] Before $div[$_]{name}\n";
					}
					
					print STDERR "\t[" . ($#div+2) . "] At the end\n";
					
					$add = getInput("Your choice?", $#div+2);
					$add--;
				}
				
				my $name = getInput("What is this level called? [DIV" . ($add+1) . "]", "DIV" . ($add+1));
				
				$div[$add]{name} = $name;
			}
			elsif ($opt =~ /d/i) {
			
				print STDERR "Which level do you want to delete?\n";
					
					for (0..$#div) {
					
						print STDERR "\t[" . ($_+1) . "] $div[$_]{name}\n";
					}
					
					my $del = getInput("Your choice?", $#div+1);
					$del--;
					
					splice(@div, $del, 1);
			}
			
			last if $opt =~ /f/;
		}
		
		print STDERR "\n\n";
		
		print STDERR "elements to delete:\n";
		
		for (0..$#delete) {

			print STDERR "\t$_. $delete[$_]\n";
		}
		
		#
		# name the output file
		# 

		print STDERR "\n\n";

		my $filename = getInput("Enter a name for the output file: ", 'output');

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

		# convert quote tags to quotation marks
		
		$text =~ s/<q>/“/g;
		$text =~ s/<\/q>/”/g;

		# delete all elements in the delete list
		
		for my $del (@delete) {
							
			$text =~ s/<$del\b.*?<\/$del\s*>//g;
			$text =~ s/<$del\s*\/>//g;			
		}
		
		# delete all closing tags
		
		$text =~ s/<\/.*?>//g;
		
		# change assigned unit tags to section boundary strings
		
		for my $i (0..$#div) {
		
			my $elem = $div[$i]{elem};
			my $name = $div[$i]{name};
		
			my $search;
		
			print STDERR "$elem->";
			
			
			if ($elem =~ s/\[(.+)=(.+)\]//) {
			
				print STDERR "$elem\n";
			
				$search = "<$elem\\b(.*?$1\\s*=\\s*\"$2\".*?)\/?>"
			}
			else {
			
				$search = "<$elem\b(.*?)>"
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
				
				$div[$level]{count} = defined $n ? $n : $div[$level]{count}++;
				
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
			
			my $tag = $text_name . " " . join(".", map {$$_{count}} @div);
			
			print OFH "<$tag> $chunk\n";
		}
		
		close OFH;
	}
}

sub getInput {

	my $prompt = shift || "?";

	my $default = shift || "";

	my $response = "";
	
	print STDERR "$prompt ";
	
	while ($response !~ /\S/) {
	
		$response = <STDIN>;
		
		chomp $response;
		$response =~ s/^\s*//;
		$response =~ s/\s*$//;
		
		if ($response eq "") { $response = $default }
	}
	
	return $response;
}

sub getStruct {

	my $doc = shift;

	# let's look for all unique paths from the document
	# root to its nodes.  this will give us some idea
	# of what kinds of structures exist in the document
	# and, if we count them, in what proportions
	
	my @struct;
	
	print STDERR "looking for document structure\n";
	
	# look for <encodingDesc>
	
	my @enc = $doc->findnodes("//encodingDesc/refsDecl");
	
	for my $i (0..$#enc) {
			
		my $enc = $enc[$i];
			
		my @unit = $enc->findnodes("state");
		
		for (@unit) {
		
			$_ = $_->getAttribute("unit");
		}
		
		unless (@unit) {
		
			@unit = $enc->findnodes("step");
			
			for (@unit) {
			
				$_ = $_->getAttribute("refunit");
			}			
		}
		
		print STDERR "\t$i: " . join(".", @unit) . "\n";
		
		if (@unit) {
			
			push @struct, { 'unit' => \@unit };
		}
		else {
			
			push @struct, { };
			print STDERR "**** NO UNITS ****\n" 
		}
		
		$i++;
	}

	return \@struct;
}