#XML-parser.pl this PERL script is designed to convert Perseus Treebank data to Storable binaries arrayed by TOKEN_ID for use by Tesserae's read_table.pl script. Includes code adapted from the O'Rielly PERL Cookbook, 2nd edition. Contributors: James Gawley.

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

	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;



use XML::LibXML;
use Storable qw(nstore retrieve);
use Data::Dumper;
print $ARGV[0] . "--\n";
my $parser = XML::LibXML->new();
my $dom = $parser->parse_file($ARGV[0]) or die;
my $root = $dom->getDocumentElement;

my $lang = $ARGV[2];
#First, go through all sentence elements and retrieve their sentence numbers.
#Then go through each word element inside them and append the word ID to the sentence ID, forming a string.
#Use the string as a hash key and store, as its value, the current count. This represents the token ID.
#Go through each sentence/word element again. Generate again their sentence-word id pairs, and retrieve the appropriate tokenIDs.
#Replace id and head elements with the appropriate with token IDs.

$tokenID = 1;
%idPairs;
my @sentences = $dom->getElementsByTagName("sentence");
foreach my $s (@sentences) {
	my $sID = $s->getAttribute("id");

	my @tokens = $s->getElementsByTagName("word");
	foreach my $t (@tokens) {
		my $wID = $t->getAttribute("id");
		my $swID = "$sID-$wID";

		$idPairs{$swID} = $tokenID;
		$tokenID++;
	}
}

foreach my $s (@sentences) {
	my $sID = $s->getAttribute("id");

	my @tokens = $s->getElementsByTagName("word");
	foreach my $t (@tokens) {
		my $wID = $t->getAttribute("id");
		my $swID = "$sID-$wID";
		
		my $hID = $t->getAttribute("head");
		if ($hID != 0) {
			my $shID = "$sID-$hID";
			my $head = $idPairs{$shID};

			$t->setAttribute("head", $head);
			my $newhead = $t->getAttribute("head");
		}
		my $word = $idPairs{$swID};
		$t->setAttribute("word", $word);
		
	}		
}
@data;
#Now go through again and assign the token ids positions in an array. inside the array make a hash containing form, head, and pos.
foreach my $s (@sentences) {
	my @tokens = $s->getElementsByTagName("word");
	foreach my $t (@tokens) {
		my %temphash = (
			DISPLAY => $t->getAttribute("form"),
			HEAD => $t->getAttribute("head"),
			POS => $t->getAttribute("postag")
		);

		
		my $tok = $t->getAttribute("word");
#		$tok--;
		$data[$tok] = \%temphash;


#		foreach my $value (values %temphash) {
#			print "$tok\t$value\n";
#		}		
#		my $useless = <STDIN>;
	}
}

open (OUTPUT, ">out.txt") or die $!;
for (0..$#data) {
	print OUTPUT "$_\t=>\t";
	foreach my $value (values %{$data[$_]}) {
		print OUTPUT "$value\t";
	}
	print OUTPUT "\n";
}


#Greek needs to be transliterated into unicode.
if ($lang = 'grc') {
	foreach my $word (@data) {
		${$word}{'DISPLAY'} = Tesserae::beta_to_uni(${$word}{'DISPLAY'});
		${$word}{'DISPLAY'} = Tesserae::standardize('grc', ${$word}{'DISPLAY'});
	}
}

#Existing Tesserae tokens need to be aligned with the tokens from the XML data.
#Do this by cycling through the token array and ignoring punctuation, matching by form.
#Retrieve the stored token array from the command line input.
my @tok_array = @{retrieve("$ARGV[1]")};
my $place = 0;
my $skip = 0;
my @new_array;
my $xml_place = -1;
my @xml_tess;
foreach my $xml_tok (@data) { #Go through the array and grab each hash of info about a given token

	$xml_place++; #Position throughout the array is stored here.
	print STDERR "XML Word $xml_place/$#data\t";
	if ($skip == 1) { 
		$place = $place_before_checking; #Reset the 'place' counter so we don't go backward or skip ahead in the Tess array.
		$skip = 0;
		next; #Reset skip flag and move on to the next XML token
	}
	my $xml_form = ${$xml_tok}{'DISPLAY'}; #The 'form' field from the original XML will be matched with the Tess 'DISPLAY' field
	my $tok_form = '';
	my $place_before_checking = $place; #Save spot in the array of Tess tokens in case match can't be found
	until ($xml_form eq $tok_form) { #The idea is to keep trying until one of the Tess tokens matches
		$tok_form = ${$tok_array[$place]}{'DISPLAY'}; 
		$place++;
		if ($place > 228645) { #An 'until' loop would otherwise lock up the program when matches can't be found.
			$skip = 1;
			last;#Breaks out of the 'until' loop
		}
	} 
	if ($skip == 1) { #move on to the next XML token
		print STDERR "\n";
		next;
	}
	else {		
		$new_array[$place] = $xml_tok;
		$xml_tess[$xml_place] = $place; #This is an 'address book' for XML-token/Tess-token pairs. It's used to replace the 'head'
										#field with the new Tess-based address system.
		my $one = ${$xml_tok}{'DISPLAY'};
		my $two	= ${$tok_array[$place]}{'DISPLAY'};
		print STDERR "$one => $two\n";
	}
	

}

#Compare each token's ID with the ID of its head.
#If they are too disparate, discount this match. 
my $new_place = -1;
foreach my $xml_tok (@new_array) {
	$new_place++;
	my $dist = $xml_tess[${$xml_tok}{'HEAD'}] - $new_place;
	$dist = abs ($dist);
	if (${$xml_tok}{'HEAD'} == 0) {next;}
	if ($dist < 100) {${$xml_tok}{'HEAD'} = ($xml_tess[${$xml_tok}{'HEAD'}] - 1);}
	else {${$xml_tok}{'HEAD'} = -1;}
}



#Kludge to fix a bug in the numbering system. Fix later!!
shift @new_array;




open (OUTPUT2, ">out2.txt") or die $!;
for (0..$#new_array) {
	print OUTPUT2 "$_\t=>\t";
	foreach my $value (values %{$new_array[$_]}) {
		print OUTPUT2 "$value\t";
	}
	print OUTPUT2 "\n";
}


nstore \@new_array, "author.work.syntax";