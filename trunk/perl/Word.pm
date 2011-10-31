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
	# from test.0.4.pl
# 	my @common_words = qw/et in non est ut cum quod ad qui esse si sed de quae quam a aut enim me te quid etiam ex hoc atque mihi id autem sunt sit se quidem quo nihil tamen ne ego nec neque ab ac haec ea ita tum modo tibi tu iam esset eius nam quem re vero quibus eo causa igitur qua ille nisi rem omnia res tam illa eum fuit nunc illud per nos sic rei ipse rebus potest sine erat vel nobis ante omnibus is pro omnium an omnes publicae c his quos rerum itaque m hic primum apud fuisse sibi aliquid publica idem sint iis eos solum ei hominum omnis posse cuius homines l ipsa at contra eam semper maxime quasi satis eorum magis ipsum iudices dicere natura causam illum illi tua quoniam saepe vos hanc multa possit senatus mea inquit scr numquam hac minus erit verum genere e populi propter p deinde illo nemo nulla cui tempore quoque tantum ista quas animi huius/;
	my @common_words = qw/et qui quis in sum tu bellum bellus per hic fero neque non jam magnus populus cum/;
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
