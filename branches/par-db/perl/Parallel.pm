package Parallel;

=head1 package Parallel
Created for tesserae project.

This is a representation of a parallel, meaning a set of words from one text (set A) and a set of words from another text (set B) where set A and B have one or more words in common.

An object of type parallel has the following variables:

=over

=item phrase_a the phrase from text A

=item phrase_b the phrase from text B

=back

=cut


use strict;

sub new {
	my $self = {};
	$self->{PHRASE_A} = undef;
	$self->{PHRASE_B} = undef;
	$self->{SCORE} = 0;
	bless($self);
	return $self;
}

sub phrase_a {
	my $self = shift;
	if (@_) { $self->{PHRASE_A} = shift }
	return $self->{PHRASE_A};
}

sub phrase_b {
	my $self = shift;
	if (@_) { $self->{PHRASE_B} = shift }
	return $self->{PHRASE_B};
}

sub score {
	my $self = shift;
	if (@_) { $self->{SCORE} = shift }
	return $self->{SCORE};
}

sub words_in_common_in_a {
	my $self = shift;
	my $phrase_a = $self->{PHRASE_A};
	my $phrase_b = $self->{PHRASE_B};
	bless ($phrase_a, "Phrase");
	bless ($phrase_b, "Phrase");
	return \@{$phrase_a->words_in_common($phrase_b)};
}

sub words_in_common_in_b {
	my $self = shift;
	my $phrase_a = $self->{PHRASE_A};
	my $phrase_b = $self->{PHRASE_B};
	bless ($phrase_a, "Phrase");
	bless ($phrase_b, "Phrase");
	return \@{$phrase_b->words_in_common($phrase_a)};
}

sub word_pairs_in_common_in_a {
	my $self = shift;
	my $phrase_a = $self->{PHRASE_A};
	my $phrase_b = $self->{PHRASE_B};
	bless ($phrase_a, "Phrase");
	bless ($phrase_b, "Phrase");
	my @pair_array;
	my @wic = @{$phrase_a->words_in_common($phrase_b)};
	for (my $i=0; $i < scalar @wic; $i++) {
		for (my $j = $i+1; $j < scalar @wic; $j++) {
			my $word0 = $wic[$i];
			my $word1 = $wic[$j];
			bless($word0, "Word");
			bless($word1, "Word");
#			print "pair: ".$word0->word().", ".$word1->word()."\n";
			my @pair = [$word0, $word1];
			push @pair_array, @pair;
		}
	}
	return \@pair_array;
}

sub word_pairs_in_common_in_b {
	my $self = shift;
	my $phrase_a = $self->{PHRASE_A};
	my $phrase_b = $self->{PHRASE_B};
	bless ($phrase_a, "Phrase");
	bless ($phrase_b, "Phrase");
	my @pair_array;
	
	my @wic = @{$phrase_b->words_in_common($phrase_a)};
	for (my $i=0; $i < scalar @wic; $i++) {
		for (my $j = $i+1; $j < scalar @wic; $j++) {
			my $word0 = $wic[$i];
			my $word1 = $wic[$j];
			bless($word0, "Word");
			bless($word1, "Word");
#			print "pair: ".$word0->word().", ".$word1->word()."\n";
			my @pair = [$word0, $word1];
			push @pair_array, @pair;
		}
	}
	return \@pair_array;
}





sub stems_in_common {
	my $self = shift;
	my $phrase_a = $self->{PHRASE_A};
	my $phrase_b = $self->{PHRASE_B};
	bless ($phrase_a, "Phrase");
	bless ($phrase_b, "Phrase");
	return $phrase_a->stems_in_common($phrase_b);	
}


sub is_interesting {
	my $self = shift;
	if (scalar @{$self->words_in_common_in_a()} > 1) {
		return 1;
	}
	return 0;
}


1;
