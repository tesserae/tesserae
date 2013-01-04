use strict;
use warnings;

use lib '/Users/chris/Sites/tesserae/perl';  #PERL_PATH
use TessSystemVars;
use EasyProgressBar;

use Storable qw(nstore retrieve);
use File::Path qw(make_path remove_tree);

# approximate size of samples in characters

my %size = (target => 500, source => 1000);
my %file = (target => 'lucan.bellum_civile.part.1',
				source => 'vergil.aeneid');
my $lang = 'la';

my %stem = %{retrieve("$fs_data/common/$lang.stem.cache")};

for my $text (qw/source target/) {

	my @bounds;

	my $opdir = "/Users/chris/Desktop/$file{$text}";

	# create output directory

	remove_tree($opdir);	
	make_path($opdir);
		
	my $base = "$fs_data/v3/$lang/$file{$text}/$file{$text}";

	my $tokenref = retrieve("$base.token");
	my @phrase = @{retrieve("$base.phrase")}; 
		
	# write samples
	
	my $pr = ProgressBar->new(scalar(@phrase));
	
	my $ndigit = length($#phrase);
	
	for my $i (0..$#phrase) {
	
		$pr->advance();
		
		my $opfile = sprintf("%s/%0${ndigit}i.txt", $opdir, $i);
		
		open (FH, ">:utf8", $opfile) || die "can't create $opfile: $!";
		
		my ($sample, $lbound, $rbound) = sample($size{$text}, $phrase[$i], $tokenref);
		
		print FH $sample;
		push @bounds, [$lbound, $rbound];
		
		close FH;
	}
	
	nstore \@bounds, "bounds.$text";
}

#
# subroutines
#

sub sample {

	my ($smin, $phraseref, $tokenref) = @_;
	
	my %phrase = %$phraseref;
	my @token  = @$tokenref;
	
	my @tokens;
	my $size = 0;
	
	for (@{$phrase{TOKEN_ID}}) {
	
		if ($token[$_]{TYPE} eq "WORD") {
		
			push @tokens, $_;
			$size += length($token[$_]{FORM});
		}
	}
	
	my $lpos = $phrase{TOKEN_ID}[0];
	my $rpos = $phrase{TOKEN_ID}[-1];
	
	while (($size < $smin) and ($rpos-$lpos < $#token)) {
		
		ADDL:
		while ($lpos > 0) {
		
			$lpos --;
			
			next ADDL unless $token[$lpos]{TYPE} eq "WORD";
			
			push @tokens, $lpos;
			
			$size += length($token[$lpos]{FORM});
			
			last ADDL;
		}
		
		ADDR:
		while ($rpos < $#token) {
		
			$rpos ++;
			
			next ADDR unless $token[$rpos]{TYPE} eq "WORD";
			
			push @tokens, $rpos;
			
			$size += length($token[$rpos]{FORM});
			
			last ADDR;
		}
	}
	
	my @stems;
	
	for (sort @tokens) {
	
		push @stems, @{stems($token[$_]{FORM})};
	}
		
	my $sample = join(" ", @stems)  . "\n";
		
	return ($sample, $lpos, $rpos);
}

sub stems {

	my $form = shift;
	
	my @stems;
	
	if (defined $stem{$form}) {
	
		@stems = @{$stem{$form}};
	}
	else {
	
		@stems = ($form);
	}
	
	return \@stems;
}
