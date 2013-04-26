package Word;

=head1 package Word
Created for tesserae project.

This is a representation of a word in a text, including its location, and surrounding text. 
An object of type word has the following variables:

=over

=item word

This is the actual word form.

=item verseno

This is an identifier for the verse number. To remain consistent, set it to the verse number identified
in the text. 

=item next

=item previous

=item phraseno

=back

Initialize an object with:

  my $word = Word->new();

Getter/Setters use their underlying variable names:

  $word->word("bonus"); # set instance variable $word to string "bonus"
  my $wordform = $word->word(); # get instance variable $word.

Other functions:

  $word->print() - dumps a representation of the object to stdout. 

=cut


use strict;

sub new {
	my $self = {};
	$self->{WORD} = undef;
	$self->{DISPLAY} = undef;
	$self->{LOCATION} = undef;
#	$self->{NEXT} = undef;
#	$self->{PREVIOUS} = undef;
	$self->{PHRASENO} = undef;
	$self->{SEMANTIC_TAGS} = [];
	$self->{MATCHED} = 0;
	$self->{PRINT_HTML} = 0;
	$self->{STEMARRAY} = [];
	bless($self);
	return $self;
}

sub word {
	my $self = shift;
	if (@_) { $self->{WORD} = shift }
	if ($self->{PRINT_HTML}  == 1) {
		if ($self->matched() == 1) {return "<span class=\"matched\" style=\"color : #f00;\">".$self->{WORD}."</span>";}
		if ($self->matched() == 2) {return "<span class=\"matched\" style=\"color : #f00;\">".$self->{WORD}."</span>";}
	} else {
		if ($self->matched() == 1) {return $self->{WORD};}
		if ($self->matched() == 2) {return $self->{WORD};}
		
	}
	#	if ($self->matched() == 1) {return "<span class=\"matched\">".$self->{WORD}."</span>";}
	#	if ($self->matched() == 2) {return "<span class=\"matched\">".$self->{WORD}."</span>";}
	return $self->{WORD};
}

#
# DISPLAY is a place to save a unicode/capitalized/etc 
# version of the word for later output

sub display {
	my $self = shift;

	if (@_) { $self->{DISPLAY} = shift }
	
	if ($self->{PRINT_HTML}  == 1) {
		if ($self->matched() == 1 or $self->matched() == 2) 
		{
			return "<span class=\"matched\" style=\"color: green;\">" 
					. $self->{DISPLAY}
					. "</span>";
		}
	} 
	return $self->{DISPLAY};
}

sub verseno {
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

sub matched {
	my $self = shift;
	if (@_) { $self->{MATCHED} = shift }
	return $self->{MATCHED};
}

sub phraseno {
	my $self = shift;
	if (@_) { $self->{PHRASENO} = shift }
	return $self->{PHRASENO};
}

sub is_common_word {
	my $self = shift;

	my @common_words;
	
	# you can pass a reference to your own array of stopwords
	
	if (@_)
	{
		my $array_ref = shift;
		
		@common_words = @$array_ref;
	
		# you can also pass the number of stopwords to use
	
		if (@_)
		{
			my $limit = shift;
		
			if ($limit > 0 && $limit < scalar(@common_words))
			{
				@common_words = @common_words[0..$limit-1];
			}
		}
	}
	else
	{
		# otherwise use the default stop list
		
		@common_words = qw/et qui2 quis1 quis2 qui1 sum1 in hic tu edo1 neque non ego ille atque cum ut fero do1 jam si per sion1 video ad omnis ipse sed ab quo amo magnus aurum suus dico2 multus venio tuus do2 possum omne sui meus nunc facio deus aut magnus1 nus primus nequeo suum terra arma manus1 huc corpus eo1 alo os1 bellum bellus vir superus quam meum noster for illic sic at res ex tamen tantus habeo sua omnes nullus teneo longus unus nam nos de2 de1 illa tum solus1 dum medius pectus virus armo volo1 amor pars ago neo1/;

		for (@common_words) { s/(\d)/\#$1/ }
		
		# Roelant's stoplist
		# my @common_words = qw/et qui quis in sum tu bellum bellus per hic fero neque non jam magnus populus cum/;

		# Greek stems
		# my @common_words = qw{de/ o( kai/ o(/s te su/ ei)mi/ e)gw/ ei)s w(s e)n me/n tis a)/ra e)pi/ a)/n1 ti/s ga/r a)lla/ ou)  au)to/s ou)do/s1 ou)do/s2 ou)de/ a)/ron nau=s pa=s e)k a)nh/r toi/ dh/ ei) ge *trw/s *)axaio/s kata/ *zeu/s polu/s a)/llos me/gas a)ta/r e)/rxomai nu=n ai)/rw fhmi/ ui(o/s xei/r toi qumo/s e)/xw h)/1 min qeo/s e)pei/ u(po/ *(/ektwr e(/ktwr tw=| ei)=mi a)po/ a)ro/w i(/ppos o(/te h)mi/ a)na/ o(/ste pe/r a)/ros ba/llw fi/los mh/ e)/nqa h)= *)axilleu/s e)mo/s para/ i(/sthmi meta/ i(/hmi so/s ma/lh ai(re/w ma/la a)/gw a)mfi/ peri/ o(/de e)/peita h)de/ a)xaia/ *)axai/a h)/2 ei)=pon ei)=don pro/teros di/dwmi pro/s bai/nw sfei=s e)/pos};
		
	}
	
	foreach (@common_words) {
		if ($self->{WORD} eq $_) {
			return 1;
		} 
	}
	return 0;
}

sub stem {
	my $self = shift;
	if (@_) { $self->{STEM} = shift }
	return $self->{STEM};
	
}

sub stemarray {
	my $self = shift;
	if (@_) { $self->{STEMARRAY} = shift }
	return $self->{STEMARRAY};
}

sub semantic_tags
{
	my $self = shift;
	if (@_)
	{
		$self->{SEMANTIC_TAGS} = shift;
	}
	
	return $self->{SEMANTIC_TAGS};
}

sub add_stem {
	my $self = shift;
	if (@_) { 
		my $stem = shift;
		push (@{$self->{STEMARRAY}}, $stem);
	}
}

sub add_semantic_tag
{
	my $self = shift;

	if (@_)
	{
		my $tag = shift;
		push @{$self->{SEMANTIC_TAGS}}, $tag;
	}
}

sub compare_to_word {
	my $self = shift;
	my $word = shift;
	bless($word,"Word");
	# print "comparing self (".$self->{WORD}.") to word: ".$word->{WORD}.": ";
	if ($self->{WORD} eq $word->{WORD}) {
	#	print "word forms match\n"; 
		return 2;
	}
	foreach  (@{$self->{STEMARRAY}}) {
		my $stem_a = $_;
		foreach  (@{$word->{STEMARRAY}}) {
			my $stem_b = $_;
		#	print "comparing $stem_a to $stem_b\n";
			if ($stem_a eq $stem_b) {
	#			print "stems match\n"; return 1;
	return 1;
			}
		}
	}
	#print "\n";
	
	return 0;	
}



sub print {
	my $self = shift;
	print "object of type WORD\n";
	print "instance variables: \n";
	print "  word:      ".$self->{WORD}."\n";
	print "  verseno:   ".$self->{VERSENO}."\n";
	print "  phraseno:  ".$self->{PHRASENO}."\n";
#	print "  previous:  ".$self->{PHRASENO}."\n";
#	print "  next:  "    .$self->{PHRASENO}."\n";
}



1;
