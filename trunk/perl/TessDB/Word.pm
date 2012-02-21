package Word;

=head1 package Word
Created for tesserae project by Roelant Ossewaarde
Modified by Chris Forstall 2012-02-20 for use with Tesserae DB

This is a representation of a word token. 
An object of type word has the following variables:

=over

=item display

This is the form that appears in the text, with capitalization, etc.

=item form

This is the inflected form for use in exact matching.

=item lemma

This is a list of possible headwords.

=item semantic

This is a list of semantic classes to which the token belongs.

=item line

This is an identifier for the verse in which the token falls.

=item link

This is a list of other words to which this one is related.

=back

=head2 methods

Initialize an object with:

	my $word = Word->new();

Getters/Setters:

	$word->setDisplay("Minerva");		# keeps capitalization, spelling
	my $string = $word->getDisplay();

	$word->setForm("Minerva");
	my $string = $word->getForm();		# returns "minerua"

	$word->setLine($line_id);
	my $line = $word->getLine();

	$word->setLemma($lemma1, $lemma2, ...);
	$word->addLemma($lemma3, ...);				
	my @lemmas = $word->getLemma();

	$word->setSemantic($semantic1, $semantic2, ...);
	$word->addSemantic($semantic3, ...);				
	my @semantic = $word->getSemantic();

	$word->setLink($word1, ...);
	$word->addLink($word2, ...);
	my @links = $word->getLink();

Others:

	my $string = $word->dump();			# diagnostic info
	my $html = $word->dump_html();		# same

=cut

use strict;

sub new {
	my $self = {};
	$self->{DISPLAY} = undef;
	$self->{FORM} = undef;
	$self->{LEMMA} = [];
	$self->{SEMANTIC} = [];
	$self->{LINE} = 0;
	$self->{LINK} = [];
	bless($self);
	return $self;
}

sub setDisplay {

	my $self = shift;
	
	$self->{DISPLAY} = shift;
}

sub getDisplay {

	my $self = shift;
	
	return $self->{DISPLAY};
}

sub setForm {

	my $self = shift;
	
	$self->{FORM} = shift;
}

sub getForm {

	my $self = shift;
	
	return $self->{FORM};
}

sub setLemma {

	my $self = shift;
	
	$self->{LEMMA} = [@_];
}

sub addLemma {

	my $self = shift;
	my $lemma = shift;
	
	push @{$self->{LEMMA}}, $lemma;
}

sub getLemma {
	
	my $self = shift;
	
	return wantarray ? @{$self->{LEMMA}} : $self->{LEMMA};
}

sub setSemantic {
	
	my $self = shift;
	
	$self->{SEMANTIC} = [@_];
}

sub addSemantic {
	
	my $self = shift;
	my $semantic = shift;
	
	push @{$self->{SEMANTIC}}, $semantic;
}

sub getSemantic {
	
	my $self = shift;
	
	return wantarray ? @{$self->{SEMANTIC}} : $self->{SEMANTIC};
}

sub setLink {
	
	my $self = shift;
	
	$self->{LINK} = [@_];
}

sub addSemantic {
	
	my $self = shift;
	my $link = shift;
	
	push @{$self->{LINK}}, $link;
}

sub getSemantic {
	
	my $self = shift;
	
	return wantarray ? @{$self->{LINK}} : $self->{LINK};
}

#
# additional methods
#

sub dump {

	my $self = shift;

	my $string = "instance of class TessDB::Word\n";
	
	for my $key (qw/DISPLAY FORM LEMMA SEMANTIC LINE LINK/) {
		
		$string .= $key . "\t";
		
		if ( ref($self->{$key}) eq "ARRAY" ) {
			
			$string .= "[" . join(", ", @{$self->{$key}}) . "]";
		}
		else {
			
			$string .= $self->{$key};
		}
		
		$string .= "\n";
	}
	
	return $string;
}

sub dump_html {
	
	my $self = shift;
	
	my $string = "<table><tr><th colspan=\"2\">instance of class TessDB::Word</th><tr>\n";
	
	for my $key (qw/DISPLAY FORM LEMMA SEMANTIC LINE LINK/) {
		
		$string .= "<tr><td>$key</td><td>";
		
		if ( ref($self->{$key}) eq "ARRAY" ) {
			
			$string .= "[" . join(", ", @{$self->{$key}}) . "]";
		}
		else {
			
			$string .= $self->{$key};
		}
		
		$string .= "</td></tr>\n";
	}
	
	$string .= "</table>\n";
	
	return $string;
}

1;
