use strict;
use warnings;

use Term::UI;
use Term::ReadLine;

use XML::LibXML;
use utf8;

binmode STDOUT, ":utf8";

#
# set up terminal interface
#

my $term = Term::ReadLine->new('myterm');

#
# read the list of files from command line
#

my @files = @ARGV;

print STDERR "checking " . scalar(@files) . " files\n";

#
# parse each file
#

for my $f (0..$#files) {
	
	#
	# step 1: parse the file
	#
	
	# create a new parser object
		
	my $parser = XML::LibXML->new();
	
	# open the file
	
	open (my $fh, "<", $files[$f])	|| die "can't open $files[$f]: $!";

	print STDERR "reading " . ($f+1) . "/" . scalar(@files) . " $files[$f]...";

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
	
	print STDERR "\n";
	
	my @title = $doc->findnodes("/TEI.2/teiHeader/fileDesc/titleStmt/title");
	
	for (@title) {
	
		$_ = $_->textContent;
		
		next unless $_;
	
		print STDERR "\t$_\n";
	}
	
	print STDERR "\n";
	
	#
	# step 2: the parsing is done, now we can search
	#         the structure of the xml document
	#
	
	my @struct = @{getStruct($doc)};
	
	#
	# step 3: get all the texts in this doc
	#
	
	my @text = $doc->findnodes("//text[not(text)]");
		
	#
	# process each text
	#
	
	for my $t (0..$#text) {

		my $text = $text[$t];

		#
		# identify the text
		#
		
		print STDERR "\n";

		print STDERR "text $f.$t.\t";
		
		my @a = $text->findnodes("attribute::*");
		
		for (@a) {
		
			$_ = $_->nodeName . "=" . $_->nodeValue;
		}
		
		print STDERR join(" ", @a) . "\n\n";
		
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
					(lc($name) eq 'line' and $elem eq 'l')) {
				
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
		# choose elements to omit
		#

		print STDERR "\n\n";

		my @omit = @{omit_dialog(\%omit, \@elem)};
				
		# delete them
				
		for my $elem_type (@omit) {
		
			my @nodes = $text->findnodes("descendant::$elem_type");
			
			next unless @nodes;
						
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
		
		$text =~ s/<foreign\s+lang="greek".*?>(.*?)<\/foreign>/beta_to_uni(\1)/gx;

		# convert quote tags to quotation marks
		
		$text =~ s/<q>/“/g;
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

sub getStruct {

	my $doc = shift;

	# let's look for all unique paths from the document
	# root to its nodes.  this will give us some idea
	# of what kinds of structures exist in the document
	# and, if we count them, in what proportions
	
	my @struct;
	
	print STDERR "Reading document header\n";
	
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
		
		if (@unit) {
			
			push @struct, join(".", @unit);
		}
		
		$i++;
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
	
	my $menu = join("\n", map { "  $_> " . $div[$_-1]{name} } (1..$#div+1));
	
	my $fix = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Change assignment for which division?\n\n" . $menu . "\n",
		allow    => [1..$#div+1],
		default  => "1");
				
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
