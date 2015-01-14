#!/usr/bin/env perl

=head1 NAME

doc_gen.pl - Generate the HTML formatted documentation for Tesserae.

=head1 SYNOPSIS

doc_gen.pl [options]

=head1 DESCRIPTION

This script should be run after configure.pl. It seeks out the script folder
and all expected subdirectories looking for scripts with POD documentation in
their headers. Then it creates a folder inside tesserae/doc/ where it stores
HTML versions of these descriptions.

=head1 OPTIONS AND ARGUMENTS

=over

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0. The contents of this file
are subject to the University at Buffalo Public License Version 1.0 (the
"License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is doc_gen.pl.

The Initial Developer of the Original Code is Research Foundation of State
University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research
Foundation of State University of New York, on behalf of University at
Buffalo. All Rights Reserved.

Contributor(s): James Gawley

Alternatively, the contents of this file may be used under the terms of
either the GNU General Public License Version 2 (the "GPL"), or the GNU
Lesser General Public License Version 2.1 (the "LGPL"), in which case the
provisions of the GPL or the LGPL are applicable instead of those above. If
you wish to allow use of your version of this file only under the terms of
either the GPL or the LGPL, and not to allow others to use your version of
this file under the terms of the UBPL, indicate your decision by deleting the
provisions above and replace them with the notice and other provisions
required by the GPL or the LGPL. If you do not delete the provisions above, a
recipient may use your version of this file under the terms of any one of the
UBPL, the GPL or the LGPL.

=cut



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
	
	$lib = catdir($lib, 'TessPerl');
}

# load Tesserae-specific modules

use lib $lib;
use Tesserae;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Pod::Html;

# initialize some variables

my $help = 0;
my $quiet = 0;

# get user options

GetOptions(
	'help'  => \$help,
   'quiet' => \$quiet
);

#
# print usage if the user needs help
#
# you could also use perldoc name.pl
	
if ($help) {

	pod2usage(1);
}

#Initialize filepath variables for the documents and scripts folders.
my @perl_scripts = get_perl_scripts($fs{script}, $fs{cgi});

#Make the string which will become the main help page.
my $html = <<END;
<html>
   <head>
      <title>Tesserae Code Documentation</title>
      <link rel="stylesheet" href="$url{css}/help.css" type="text/css" />
   </head>
   <body>
      <div id="main">
         <h1>Code Documentation</h1>
         <p>
            This document is designed to help users of the home-version of 
            Tesserae to install, use, and modify the tool as needed. The 
            project code can be found at <a 
            href="github.com/tesserae/tesserae">github.com/tesserae/tesserae
            </a>.
	      </p>
         
         <h2>Navigating the Folders</h2>
	      <p>
            <b>cgi-bin:</b> This folder contains scripts that are read when
            finding and displaying search results online. The scripts read the
            user’s specified target and source text data, identify meaningful 
            instances of intertextuality, and display the results online. 
            These scripts make up the core part of a Tesserae search request.
         </p>
         <p>
            <b>css:</b> This folder contains files that set the environment 
            (such as color, font, spacing, etc.) for search results displayed
            online.
         </p>
         <p>
            <b>data</b>: This folder contains permanent data generated in the 
            install process.
         </p>
         <ul>
            <li>
               The batch folder is populated by one of the steps in the batch
               processing system, which allows multiple features to be run at 
               once.
            </li>
            <li>
               The bench folder contains pre-run data for test sets, 
               Aeneid/Iliad and BC/Aeneid. The common folder contains
               frequently used files such as Greek and Latin dictionaries, 
               tools for recognizing and storing word stems during a search, 
               abbreviation lists, stop words lists, etc. Many scripts in the 
               Tesserae program access these files regularly. 
            </li>
            <li>
               The synonymy folder contains files with Latin and Greek synonym
               lists from the New Testament comparisons. These files are used
               by the trans1 and trans2 features.
            </li>
            <li>
               The v3 folder (referring to version three of the Tesserae
               project) contains the core data files for individual texts. 
               After running the full install process as detailed above, the
               user should see at least two subfolders here, grc and la.
            </li>
            <li>
               The Greek and Latin folders contain a large number of folders
               organized by author in the format author.name_of_work. Each work
               has nine specific data files as follows:
               <ul>
                  <li>
                     author.name_of_work.freq_score_stem – Each stem in the
                     text is stored with a frequency statistic calculated by
                     the number of times that stem appears in that author’s 
                     corpus divided by the total number of stems in the 
                     author’s corpus.
                  </li>
                  <li>
                     author.name_of_work.freq_score_word - Each exact word in
                     the text is stored with a frequency statistic calculated
                     by the number of times that exact word appears in that 
                     author’s corpus divided by the total number of words in
                     the author’s corpus.
                  </li>
                  <li>
                     author.name_of_work.freq_stop_stem – Frequency 
                     statistics for stop word stems (ie, common stems that are
                     not considered to make meaningful allusions).
                  </li>
                  <li>
                     author.name_of_work.freq_stop_word - Frequency statistics
                     for exact stop words (ie, common words that are not 
                     considered to make meaningful allusions).
                  </li>
                  <li>
                     author.name_of_work.index_stem – An index of each stem 
                     and its location in the text.
                  </li>
                  <li>
                     author.name_of_work.index_word – An index of each exact
                     word and its location in the text.
                  </li>
                  <li>
                     author.name_of_work.line  - A hash of the lines in 
                     which each stem appears.
                  </li>
                  <li>
                     author.name_of_work.phrase – A hash of the phrases 
                     (sentences) in which each stem appears.
                  </li> 
                  <li>
                     author.name_of_work.token – A hash of the locations of
                     each word as it appears with its original markers such
                     as capitalization.
                  </li>
               </ul>
            </li>
         </ul>
         <p>
            <b>doc</b>: This folder contains files with project documentation
            and user instructions.
         </p>
         <p>
            <b>html</b>: This folder contains files that run the web interface
            of the Tesserae home page.
         </p>
         <p>
            <b>images</b>: This folder contains a collection of frequently
            used pictures such as logos, web banners, etc.
         </p>
         <p>
            <b>scripts</b>:
            <ul>
END


#Initialize a hash which will contain the script names and the link addresses
my %toc;

foreach my $full_path (@perl_scripts) {
	
	my ($vol, $dir, $script) = File::Spec->splitpath($full_path);
   
	#Use the Pod::Html to call pod2html, which is included with PERL 5 distributions.
   pod2html(
      "--infile=$full_path",
      "--outfile=" . catfile($fs{doc}, "$script.html"),
      "--css=$url{css}/doc.css"
   );
	
	$toc{$script} = "$url{doc}/$script.html";
}


#Create the index of documents

foreach my $script (sort keys %toc) {
	$html .= "\n<li><a href='$toc{$script}'>$script</a></li>\n";

}

$html .= <<END;
            </ul>
         </p>
         <p>
            <b>texts</b>: This folder contains specially formatted text files
            that are ready to be run in a search. Each work is a separate .tess
            file; larger works are also split into separate files for each 
            book. The structure of this folder is parallel to that of the 
            data/v3 folder.
         </p> 
         <p>
            <b>tmp</b>: This folder is where temporary output is stored. It 
            behaves like a scratchpad for Tesserae while a search is running.
            If the user stops a search in the middle of processing, files 
            besides err.log, output.txt, temporary-session.xml, and tmp.csv
            (these are all template files) must be deleted.
         </p>
         <p>
            <b>xsl</b>: This folder contains files which read .xml files for
            web display
         </p>
      </div>
   </body>
</html>
END

my $index_file = catfile($fs{doc}, "index.html");

open (my $fh, ">:utf8", $index_file) or die $!;
print $fh $html;

# this temp file gets created by the pod2html process
for my $tmp_file (glob("pod2htm*")) {
	print STDERR "deleting $tmp_file\n" unless $quiet;
   unlink $tmp_file;
}

# subroutines

sub get_perl_scripts {
   my @dir = @_;
   
   my @perl_scripts;
   
   for my $dir (@dir) {
      print STDERR "checking $dir\n" unless $quiet;
      
      opendir(my $dh, $dir) or die "Can't read $dir: $!";
      
      my @files = grep {$_ !~ /^\./} readdir($dh);
      @files = map {catfile($dir, $_)} @files;
      
      for my $file (@files) {
         if (-d $file) {
            push @perl_scripts, get_perl_scripts($file);
         }
         else {
            if ($file =~ /\.pl$/) {
               push @perl_scripts, $file;
            }
         }
      }
      
      closedir($dh);
   }
   
   return @perl_scripts;
}