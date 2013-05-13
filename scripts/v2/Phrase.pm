package Phrase;
use strict;

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
use v2::Word;

#my @wordarray;

sub new {
	my $self = {};
	$self->{PHRASE} = undef;
	$self->{LOCATION} = undef;
	$self->{NEXT} = undef;
	$self->{PREVIOUS} = undef;
	$self->{PHRASENO} = undef;
	$self->{WORDARRAY} = [];
	$self->{WORDSFORCOMPARISONARRAY} = [];
	bless($self);
	#return $self;
}

sub phrase {
	my $self = shift;
	if (@_) { $self->{PHRASE} = shift }
	return $self->{PHRASE};
}

sub location {
	my $self = shift;
	if (@_) { $self->{LOCATION} = shift }
	return $self->{LOCATION};
}

sub next {
	my $self = shift;
	if (@_) { $self->{NEXT} = shift }
	return $self->{NEXT};
}

sub previous {
	my $self = shift;
	if (@_) { $self->{PREVIOUS} = shift }
	return $self->{PREVIOUS};
}

sub phraseno {
	my $self = shift;
	if (@_) { $self->{PHRASENO} = shift }
	return $self->{PHRASENO};
}

sub wordarray {
	my $self = shift;
	if (@_) { $self->{WORDARRAY} = shift }
	return $self->{WORDARRAY};
}

sub add_word {
	my $self = shift;
	if (@_) { 
		my $word = shift;
		bless($word, "Word");
#		print "Word: ".$word->word()."\n";
		push (@{$self->{WORDARRAY}}, $word);

		if ($word->is_common_word() == 0) {
			my $i = 0;
			for (@{$self->{WORDSFORCOMPARISONARRAY}}) {
				if ($_->{WORD} eq $word->{WORD}) {$i++;}
			}
			if ($i == 0) {	push (@{$self->{WORDSFORCOMPARISONARRAY}}, $word); }
		}
	} else {
		die "can't call method add_word() on an instance of Phrase without an argument!";
	}
}

sub print {
	my $self = shift;
	my $i=0;
	print "object of type PHRASE\n";
	print "instance variables: \n";
	print ref($self->{PHRASE});
	print "number of words: ".scalar @{$self->{WORDARRAY}}."\n";
	print "words: \n";
	foreach (@{$self->{WORDARRAY}}) {
		print "word ".$i."\n";
		my $word = $_;
		bless ($word, "Word");
	#	print $word;
		$word->print();
		$i++;
		print "\n";
	}
}

sub distance {
	my $self = shift;
	my $word1 = shift;
	my $word2 = shift;
	my $i=0;
	my $startpos = 0;
	my $endpos = 0;
	bless($word1, "Word");
	bless($word2, "Word");
#	print "calculating distance between ".$word1->word()." and ".$word2->word()."\n";
	if ($word1 == $word2) {return 0;}
	foreach (@{$self->{WORDARRAY}}) {
		if ($_ == $word1) {
			$startpos = $i;
		#	print "found word 1 on position ".$i."\n";
		} 
		else {
			if ($_ == $word2) {
				$endpos = $i;
		#		print "found word 2 on position ".$i."\n";
			} 
		}
		
		$i++;
	}
	return $endpos - $startpos;
}

sub compare {
	my $self = shift;
	my $phrase = shift;
	my @words = $self->stems_in_common($phrase);
	return scalar @words;
}

sub short_print {
	my $self = shift;
	my $i=0;
	my $previous_verseno = '';
	if ($self->{WORDARRAY} == 0) {
		print "wordarray is 0\n";
	} else {
		print "PHRASE: (".scalar @{$self->{WORDARRAY}}.") ";
	}
	foreach (@{$self->{WORDARRAY}}) {
		my $word = $_;
		bless ($word, "Word");
		#	print $word;
		if (!($word->verseno() eq $previous_verseno)) {
			print " (".$word->verseno().") ";
			$previous_verseno = $word->verseno();
		}
		print $word->word()." ";
	}
}

sub short_print2 {
	my $self = shift;
	my $i=0;
	my $previous_verseno = '';
	my $string = "";
	foreach (@{$self->{WORDARRAY}}) {
		my $word = $_;
		bless ($word, "Word");
		#	print $word;

		$string = $string." ".$word->word();
	}
	return $string;
}

sub short_print3 {
	my $self = shift;
	my $i=0;
	my $previous_verseno = '';
	my $string = "";
	foreach (@{$self->{WORDARRAY}}) {
		my $word = $_;
		bless ($word, "Word");
		#	print $word;
		my $cleanword = $word->word();
		$cleanword =~ s/<(.*?)>//gi;
		
		$string = $string." ".$cleanword;
	}
	return $string;
}

sub verseno {
	my $self = shift;
	my $word = @{$self->{WORDARRAY}}[0];
	bless ($word, "Word");
	my $verseno = $word->verseno();
	return $verseno;
}

sub num_matching_words {
	my $self = shift;
	my $num_matched = 0;
	my @words = @{$self->{WORDARRAY}};
	foreach (@words) {
		my $word = $_;
		bless($word, "Word");
		if ($word->matched() > 0) {
			$num_matched++;
		}
	}
	return $num_matched; 
	
}



sub words_in_common {
	my @words_in_common = ();
	my $self = shift;
	my $num_parallel_words = 0;
	my $success_threshold = 3; 					# algorithm will give up after finding $success_threshold; low value = faster execution. 
	my $debug_output = 0; 						# set to 1 to enable debugging output in this function. 0: no output at all. 
	if (@_) { 
		my $phrase = shift;
		bless($phrase, "Phrase");
		if (scalar @{$self->{WORDARRAY}} <= 1) {
			#			print "skipping because this phrase is too short (<2)\n";
			return \@words_in_common;
		}
		if ($debug_output == 1) {
			print "comparing \"";
			$self->short_print();
			print "\" to \"";
			$phrase->short_print();
			print "\"\n";
		}
		foreach (@{$self->{WORDARRAY}}) {
			my $word_a = $_;
			bless($word_a, "Word");
			foreach (@{$phrase->{WORDARRAY}}) {
				my $word_b = $_;
				bless($word_b, "Word");
				if ($word_a->compare_to_word($word_b) > 0) {
					$num_parallel_words++;
					push @words_in_common, $word_a;
					last;
				}
			}
		}
	}
				

		#	if ($num_parallel_words > $success_threshold) {
		#		return @words_in_common;
		#	}
	return \@words_in_common;
}

sub semantic_comparison
{	
	my $self = shift;
	my $phrase = shift;
	my $score = 0;
	
	bless $phrase, 'Phrase';
	
	for my $word_a ( @{ $self->wordarray } )
	{

		bless $word_a, 'Word';
			
		for my $word_b ( @{ $phrase->wordarray } )
		{
			
			bless $word_b, 'Word';
			
			my $word_score;
			my $tag_count;
				
			for my $tag_a ( @{ $word_a->semantic_tags } )
			{
					
				for my $tag_b ( @{ $word_b->semantic_tags } )
				{
					
					print STDERR "$tag_a ~ $tag_b : ";
					
					if (lc($tag_a) eq lc($tag_b))
					{
						print STDERR "1\n";
						
						$word_score++;
					}
					else
					{
						my @tag_words_a = split / /, lc($tag_a);
						my @tag_words_b = split / /, lc($tag_b);
						
						my %uniq_a;
						
						for (@tag_words_a)
						{
							$uniq_a{$_} = 1;
						}
						
						my %uniq_b;
						
						for (@tag_words_b)
						{
							$uniq_b{$_} = 1;
						}
						
						my %intersection;
						
						for (keys %uniq_a, keys %uniq_b)
						{
							$intersection{$_}++;
						}
						
						$word_score += ( scalar( grep { $_ == 2 } values %intersection ) / scalar( values %intersection ) );
						
						print STDERR ( scalar( grep { $_ == 2 } values %intersection ) / scalar( values %intersection ) ) . "\n";
					}
						
					$tag_count++;
				}
			}
			
			if ($tag_count > 0)
			{
				$score += $word_score / $tag_count; 
			}
		}
	}
	
	return $score;
}

sub stems_in_common {
	# this is now deprecated, now that all the comparisons are actually made on the word-level, not phraselevel
	my @words_in_common;
	my $self = shift;
	my $num_parallel_words = 0;
	my $success_threshold = 3; 				# algorithm will give up after finding $success_threshold; low value = faster execution. 
	my $debug_output = 0; 						# set to 1 to enable debugging output in this function. 0: no output at all. 
	if (@_) { 
		my $phrase = shift;
		bless($phrase, "Phrase");

		if (scalar @{$self->{WORDARRAY}} <= 1) {
			#			print "skipping because this phrase is too short (<2)\n";
			return 0;
		}
		if ($debug_output == 1) {
			print "comparing \"";
			$self->short_print();
			print "\" to \"";
			$phrase->short_print();
			print "\"\n";
		}
		
		foreach (@{$self->{WORDARRAY}}) {
			my $word_a = $_;
			bless($word_a, "Word");
			
			foreach (@{$phrase->{WORDARRAY}}) {
				my $word_b = $_;
				bless($word_b, "Word");

				foreach  (@{$word_a->{STEMARRAY}}) {
					my $stem_a = $_;

					foreach  (@{$word_b->{STEMARRAY}}) {
						my $stem_b = $_;
						#	print "comparing $stem_a to $stem_b\n";

						if ($stem_a eq $stem_b) {
							if ($word_a->is_common_word()) {
								# print "removing A word ".$word_a->word()." because it is too common.\n";
								last;
								
							} else {
								if ($word_b->is_common_word()) {
							# 		print "removing B word ".$word_b->word()." because it is too common.\n";
								} else {
									$num_parallel_words++;
									push @words_in_common, $stem_a;
								}
							}
							last;
						}
					}
				}
			}
			if ($num_parallel_words > $success_threshold) {
				return @words_in_common;
			}
		}
	}
	return \@words_in_common;
}



1;
