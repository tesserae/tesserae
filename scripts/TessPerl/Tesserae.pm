package Tesserae;

use File::Spec::Functions;
use File::Basename;
use Storable qw(nstore retrieve);
use utf8;
use Unicode::Normalize;
use Encode;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(%top $apache_user %is_word %non_word $phrase_delimiter %ancillary %fs %url);

our @EXPORT_OK = qw(uniq intersection tcase lcase beta_to_uni alpha stoplist_hash stoplist_array check_prose_list lang);

our $VERSION = '3.1.0_0';

#
# read config file
#

my $lib = (fileparse($INC{'Tesserae.pm'}, '.pm'))[1];

my ($fs_ref, $url_ref) = read_config(catfile($lib, '..', 'tesserae.conf'));

our %fs  = %$fs_ref;
our %url = %$url_ref;

# optional modules

my $override_stemmer  = check_mod("Lingua::Stem");

# cache for language lookup

my %lang;

# this is used by Lingua::Stem

my $stemmer;

unless ($override_stemmer) {

	$stemmer = Lingua::Stem->new();
}

# feature dependencies

our %feature_dep = (
	
	'trans1' => 'stem',
	'trans2' => 'stem',
	'syn'    => 'stem'
);

# per-feature frequency tables to use in scoring

our %feature_score = (

	'word'   => 'word',
	'stem'   => 'stem',
	'trans1' => 'stem',
	'trans2' => 'stem',
	'syn'    => 'syn',
	'3gr'    => '3gr'
);

# some features require special code

my %feature_override = (

	'3gr'    => \&chr_ngrams,
	'porter' => \&porter
);


# cache for feature lookup

my %feat;

#
# some language-processing stuff
#

my $re_dia   = qr/[\x{0313}\x{0314}\x{0301}\x{0342}\x{0300}\x{0308}\x{0345}]/;
my $re_vowel = qr/[αειηουωΑΕΙΗΟΥΩ]/;

# punctuation marks which delimit phrases

our $phrase_delimiter = '[\.\?\!\;\:]';

# what's a word in various languages

my $wchar_greek = '\w\'';
my $wchar_latin = 'a-zA-Z';

our %non_word = (
	'la'  => qr([^$wchar_latin]+), 
	'grc' => qr([^$wchar_greek]+),
	'en'  => qr([^$wchar_latin]+) 
	); 
	
our %is_word = (
	'la'  => qr([$wchar_latin]+), 
	'grc' => qr([$wchar_greek]+),
	'en'  => qr('?[$wchar_latin]+(?:['-][$wchar_latin]*)?) 
	);

########################################
# subroutines
########################################

sub read_config {

	my $config = shift;
	
	my %par;
	
	my $section;

	open (FH, "<", $config) or die "can't open $config: $!";

	while (my $line = <FH>) {
	
		chomp $line;
	
		$line =~ s/#.*//;
		
		next unless $line =~ /\S/;
		
		if ($line =~ /\[(.+)\]/) { 
		
			$section = $1
		}		
		elsif ($line =~ /(\S+)\s*=\s*(\S+)/) {
				
			my ($name, $value) = ($1, $2);
						
			$par{$section}{$name} = $value;			
		}
		elsif ($line =~ /(\S+)/) {
		
			push @{$par{$section}}, $1;
		}
	}

	close FH;
		
	return ($par{path_fs}, $par{path_url});
}

sub uniq {

	# removes redundant elements

   my @array = @{$_[0]};			# dereference array to be evaluated

   my %hash;							# temporary
   my @uniq;							# create a new array to hold return value

	for (@array) {

		$hash{$_} = 1; 
	}
											
   @uniq = sort( keys %hash);   # retrieve keys, sort them

   return \@uniq;
}


sub intersection {  

	# arguments are any number of arrays,
	# returns elements common to all as 
	# a reference to a new array

   my %count;			# temporary, local
   my @intersect;		# create the new array

   for my $array (@_) {         # for each array

      for (@$array) {           # for each of its elements (assume no dups)
         $count{$_}++;          # add one to count
      }
   }

	# keep elements whose count is equal to the number of arrays

   @intersect = grep { $count{$_} == 2 } keys %count;

	# sort results

   @intersect = sort @intersect;

   return \@intersect;
}

#
# language-specific lower-case and title-case functions
#

sub standardize {

	my $lang = shift;
	
	my @string = @_;
	
	for (@string) {

		$_ = NFKD($_);
		$_ = lcase($lang, $_);

		s/\d//g;
				
		# latin
		
		if ($lang eq 'la') {
		
			tr/jv/iu/;	  # replace j and v with i and u throughout
			s/\W//g;  # remove non-word characters
		}
				
		# greek - unicode
		
		elsif ($lang eq 'grc') {
		
			# change grave accent (context-specific) to acute (dictionary form)
			
			s/\x{0300}/\x{0301}/g;

			s/^(${re_dia}+)(${re_vowel}{2,})/$2/;
			s/^(${re_dia}+)(${re_vowel}{1})/$2$1/;
			s/σ\b/ς/;
			
			# remove non-word chars
			
			s/\W//g;
		}
		
		# greek - beta code
		
		elsif ($lang eq 'betacode') {
		
			s/\\/\//;	  # change grave accent (context-specific) to acute (dictionary form)
			s/0-9\.#//g;  # remove numbers
		}
		
		# english
		
		elsif($lang eq 'en') {
		
			s/[^a-z]//g; # remove everything but letters
		}
		
		# everything else
		
		else {
		
			# remove non-word chars
			
			s/\W//g;  
		}
	}
	
	return wantarray ? @string : shift @string;	
}

sub lcase {

	my $lang = shift;

	my @string = @_;

	for (@string) {
	
		# greek - beta code
	
		if ($lang eq 'betacode') {

			s/^\*([\(\)\/\\\|\=\+]*)([a-z])/$2$1/;
		}
		
		# everything else

 		else {

			$_ = lc($_);
		}		
	}

	return wantarray ? @string : shift @string;
}

sub tcase {

	my $lang = shift;

	my @string = @_;
	
	for (@string) {

		$_ = lcase($lang, $_);
		
		# Greek - Beta Code
	
		if ($lang eq 'betacode') {
		
			s/^([a-z])([\(\)\/\\\|\=\+]*)/\*$2$1/;
		}
		
		# everything else
		
		else {
		
			$_ = ucfirst($_);
		}
	}

	return wantarray ? @string : shift @string;
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

sub alpha {

	my ($lang, $form) = @_;

	if ($lang eq 'betacode') {
	
		$form = beta_to_uni($form);
	}

	$form =~ s/[^[:alpha:]]//;

	return $form;
}

# load a frequency file and save it as a hash

sub stoplist_hash {

	my $file = shift;
	
	my %index;
	
	open (FREQ, "<:utf8", $file) or die "can't read $file: $!";
	
	my $head = <FREQ>;
	
	my $total = 1;
	
	if ($head =~ /count\D+(\d+)/) {
	
		$total = $1;
	}
	else {
	
		seek(FREQ, 0, 0);
	}
	
	while (my $line = <FREQ>) {
	
		next if $line =~ /^#/;
	
		my ($key, $count) = split("\t", $line);
		
		$index{$key} = $count/$total;
	}
	
	close FREQ;
	
	return \%index;
}

# load a frequency file and just return the forms in order

sub stoplist_array {

	my $file = shift;
	my $n    = shift;
	
	my @stoplist;
	my $counter = 0;
	
	open (FREQ, "<:utf8", $file) or die "can't read $file: $!";
	
	while (my $line = <FREQ>) {
	
		next if $line =~ /^#/;
	
		last if defined $n and $counter >= $n;
		$counter ++;

		my ($key, $count) = split("\t", $line);

		push @stoplist, $key;
	}
	
	close FREQ;
	
	return \@stoplist;
}


# loads a module if it's available
# 
# returns 1 on failure
#         0 on success

sub check_mod {

	my $m = shift;
			
	eval "require $m";
	
	my $failed = 0;
		
	if ($@) {
	
		# print STDERR "Error loading $m:\n$!\n";
		$failed = 1;
	}
	
	return $failed;
}

# check the list to see whether a text is marked as prose

sub check_prose_list {

	my $name = shift;
		
	my $file_prose_list = catfile($fs{text}, 'prose_list');
	
	return 0 unless (-s $file_prose_list);
	
	open (FH, '<:utf8', $file_prose_list) or die "can't read $file_prose_list";
	
	while (my $line = <FH>) { 
	
		chomp $line;
		
		$line =~ s/#.*//;
		
		next unless $line =~ /\S/;
		
		return 1 if $name =~ /$line/;
	}
	
	return 0;
}


#
# retrieve the full list of texts for a language corpus
#

sub get_textlist {
	
	my ($lang, %opt) = @_;
	
	my $directory = catdir($fs{data}, 'v3', $lang);

	opendir(DH, $directory);
	
	my @textlist = map { decode('utf8', $_) } grep {/^[^.]/} readdir(DH);
	
	closedir(DH);
	
	if ($opt{-no_part}) {
	
		@textlist = grep { $_ !~ /\.part\./ } @textlist;
	}
		
	if ($opt{-sort}) {
	
		@textlist = sort {text_sort($a, $b)} @textlist;
	}
	
	if (defined $opt{-prose}) {
		
		@textlist = grep { Tesserae::check_prose_list($_) == $opt{-prose} } @textlist;
	}
		
	return \@textlist;
}

# sort texts and put parts in numerical order

sub text_sort {

	my ($l, $r) = @_;

	unless ($l =~ /(.+)\.part\.(.+)/) {
	
		return ($l cmp $r);
	}
	
	my ($lbase, $lpart) = ($1, $2);
	
	unless ($r =~ /(.+)\.part\.(.+)/) {
	
		return ($l cmp $r);
	}
	
	my ($rbase, $rpart) = ($1, $2);	
	
	unless ($lbase eq $rbase) {
	
		return ($l cmp $r)
	}
	
	for ($lpart, $rpart) {
	
		s/\..*//;
	
		return ($lpart cmp $rpart) if /\D/;
	}
	
	return ($lpart <=> $rpart);
}

# check a text's language

sub lang {
	
	my ($text, $lang) = @_;
	
	my $file_lang = catfile($fs{data}, 'common', 'lang');

	if (! %lang and -s $file_lang) {
		
		%lang = %{retrieve($file_lang)};
	}
	
	if ($lang) {
	
		$lang{$text} = $lang;
		nstore \%lang, $file_lang;
	}
	
	return $lang{$text};
}

# check the feature dictionary

sub feat {

	my ($lang, $feature, $form, %opt) = @_;
	
	my $flag = 0;

	# if the language hasn't already been used,
	# load up the feature dictionary
	
	if (not defined $feat{$lang}{$feature}) {
		
		unless (defined $feature_override{$feature}) {
	
			my $file_dict = catfile($fs{data}, 'common', join('.', $lang, $feature, 'cache'));

			# print STDERR "loading dictionary: $file_dict\n";
	
			$feat{$lang}{$feature} = retrieve($file_dict);
		}
	}

	# if an array ref passed, look up all the forms in the array

	my @form;
	my @indexable;

	if (ref($form) eq 'ARRAY') {
		
		@form = @$form;
	}
	else {
	
		@form = ($form);
	}
	
	# if this feature depends on another, 
	# calculate that one first
	
	if (defined $feature_dep{$feature}) {
	
		@form = @{feat($lang, $feature_dep{$feature}, \@form, %opt)};
	}
			
	for $form (@form) {
		
		# if special code defined for this feature, 
		# use it, otherwise, use generic code.

		if (defined $feature_override{$feature}) {

			push @indexable, @{$feature_override{$feature}->($lang, $form, %opt)};
		}		
		else {
		
			# return the features listed in the dictionary,
			# or the form itself if nothing found.	
		
			if (defined $feat{$lang}{$feature}{$form}) {

				my @indexable_ = @{$feat{$lang}{$feature}{$form}};
				
				if ($opt{force}) { @indexable_ = @indexable_[0] }
				
				push @indexable, @indexable_;
			}
			else {

				push @indexable, $form;
			}
		}
	}

	return uniq(\@indexable);
}

sub write_freq_stop {
	
	my ($name, $feature, $index_ref, $quiet) = @_;
	
	my %index = %$index_ref;
	
	my $lang = lang($name);
	
	my %count;
	
	my $total = 0;
	
	for (keys %index) {
		
		$count{$_} = scalar(@{$index{$_}});
		$total    += $count{$_};
	}
	
	my $file = catfile($fs{data}, 'v3', $lang, $name, "$name.freq_stop_$feature");
	
	print STDERR "Writing $file\n" unless $quiet;

	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count{$b} <=> $count{$a}} keys %count) {
		
		print FREQ sprintf("%s\t%i\n", $_, $count{$_});
	}
	
	close FREQ;
}


sub write_freq_score {

	my ($name, $feature, $index_ref, $quiet) = @_;
	
	my %index = %$index_ref;
	
	my $lang = lang($name);
		
	my %by_feature;
	my %count_by_word;
	my $total;

	# count and index words by feature
	
	for my $form (keys %index) {

		$count_by_word{$form} += scalar(@{$index{$form}});
		
		$total += $count_by_word{$form};
		
		for my $feat (@{feat($lang, $feature, $form)}) {		

			push @{$by_feature{$feat}}, $form;
		}
	}
	
	for my $feat (keys %by_feature) {
	
		$by_feature{$feat} = Tesserae::uniq($by_feature{$feat});
	}
	
	#
	# calculate the stem-based count
	#
	
	my %count_by_feature;
	
	for my $word1 (keys %count_by_word) {
	
		# this is to remember what we've
		# counted once already.
		
		my %already_seen;
				
		# for each of its indexable features
		
		for my $feat (@{feat($lang, $feature, $word1)}) {
			
			# count each of the words 
			# with which it shares that stem
			
			for my $word2 (@{$by_feature{$feat}}) {
				
				next if $already_seen{$word2};
				
				$count_by_feature{$word1} += $count_by_word{$word2};
				
				$already_seen{$word2} = 1;
			}
		}
	}
	
	my $file = catfile($fs{data}, 'v3', $lang, $name, "$name.freq_score_$feature");
	
	print STDERR "Writing $file\n" unless $quiet;
	
	open (FREQ, ">:utf8", $file) or die "can't write $file: $!";
	
	print FREQ "# count: $total\n";
	
	for (sort {$count_by_feature{$b} <=> $count_by_feature{$a}} keys %count_by_feature) { 
	
		print FREQ sprintf("%s\t%i\n", $_, $count_by_feature{$_});
	}
	
	close FREQ;
}

#
# turn a bunch of .tess filenames into names of installed texts.
#

sub process_file_list {
	
	my ($listref, $lang, $optref) = @_;
	my @list_in = @$listref;
	my %opt     = %$optref;
	
	my %list_out = ();

	for my $file_in (@list_in) {
	
		# large files split into parts are kept in their
		# own subdirectories; if an arg has no .tess extension
		# it may be such a directory

		if (-d $file_in) {

			opendir (DH, $file_in);

			my @parts = (grep {/\.part\./ && -f} map { catfile($file_in, $_) } readdir DH);

			push @list_in, @parts;
					
			closedir (DH);
		
			# move on to the next full text

			next;
		}
	
		my ($name, $path, $suffix) = fileparse($file_in, qr/\.[^.]*/);
	
		next unless ($suffix eq ".tess");
		
		# get the language for this doc.
		
		if ( defined $lang and $lang ne "") {
			
			lang($name, $lang);
		}
		elsif ( defined lang($name) ) {
		}
		elsif (Cwd::abs_path($file_in) =~ m/$fs{text}\/([a-z]{1,4})\//) {

			lang($name, $1);
		}
		else {

			warn "Skipping $file_in: can't guess language";
			next;
		}

		$list_out{$name} = $file_in;
	}

    #Remove erroneously added blank file names.

    for my $key (keys %list_out) {
        unless ($key) {
            delete $list_out{$key};
        }
    }

	if ($opt{filenames}) {
		
		return \%list_out;
	}
	else {
	
		return [sort keys %list_out];
	}
}

sub porter {

	my ($lang, $form, %opt) = @_;
	
	$lang = ($lang eq 'en' ? 'EN-UK' : uc($lang));
	
	if ($stemmer->get_locale ne $lang) {
	
		$stemmer->set_locale($lang);
	}
	
	return $stemmer->stem($form);
}

sub chr_ngrams {

	my ($lang, $form, %opt) = @_;
	
	# set n to 1 less than the n you want:
	# e.g., n=2 produces 3-grams.
	
	my $n = 2;
	
	# remove accents, etc.
		
	$form =~ s/[^[:alpha:]]//g;
	
	my @chr = (split //, $form);
	
	my %ngram;
	
	for (my $i = 0; $i <= $#chr - $n; $i++) {
	
		$ngram{join("", @chr[$i..$i+$n])} ++;
	}
	
	return [keys %ngram];
}

sub initialize_lingua_stem {

	if ($override_stemmer) {
	
		print STDERR "Tesserae can't find Lingua::Stem. Falling back to stem dictionary if one exists\n";
	}
	else {
	
		$feature_override{'stem'} = $feature_override{'porter'};
	}
}

sub get_base {

	my $text = shift;
	
	my $lang = lang($text);
	
	unless ($lang) {
	
		print STDERR "Can't find language for $text. Have you run add_column.pl?\n";
		return undef;
	}
	
	my $base = catfile($fs{data}, 'v3', $lang, $text, $text);
	
	unless (-e "$base.token") {
	
		print STDERR "Can't find token data for $text. Have you run add_column.pl?\n";
		return undef;
	}
	
	return $base;
}
1;
