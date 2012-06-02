use strict;
use warnings;

# Roelant saves dictionary headword information as a hash
#
# the keys to the hash are word forms as they appear in the text
#
# the value for each key is a reference to an anonymous array
# containing possible headwords.
#
# he saves this data structure to the file "stem.cache" using
# the module Storable.

# this line gives us access to Storable, in particular its 
# 'retrieve' function

use Storable qw(retrieve);

# here we retrieve the data that Roelant has stored
#
# what we get is a reference to the hash.  By putting %{ }
# around the function we de-reference its return value,
# we get access to the hash itself, not just a pointer to it.

my %cache = %{ retrieve("stem.cache") };

# this hash will hold headword counts.
#
# so if 500 words have 2 possible headwords,
# then $count{2} == 500

my %count;

# go through each of the keys in the headword cache

for (keys %cache)
{

	# this array will hold all the headwords for that key
	#
	# once again, we have to dereference to get the actual array

	my @lemma = @{ $cache{$_} };

	# scalar(@lemma) gives the number of headwords in @lemma
	# the line below uses that value as the key to %count,
	# and increments the value at that key

	$count{scalar(@lemma)}++;
}


# this loop then goes over the %count hash and prints its values
#
# the sort algorithm just makes sure the keys are in numerical order

for (sort {$a <=> $b} keys %count)
{

	# the output is in two columns separated by a tab
	# the first is number of possible headwords, 
	# the second is number of words having that number of possible headwords

	print "$_\t$count{$_}\n";
}
