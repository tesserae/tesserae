# import regular expression module

import re

# for writing to stderr

import sys

# this is for saving data

import pickle

# this is for drawing progress bars

from progressbar import ProgressBar, Percentage, Bar

# the path to data

tess_data = "/Users/chris/Sites/tesserae/data"
path_data = "/Volumes/CWFDATA/semantics"

# this will be our corpus.  
# it's the english definitions from whitaker's words

headword = []
full_def = []
corpus = []
lookup = dict()
wc = dict()

# open the file, create a file object

f = open(tess_data + "/common/DICTPAGE.RAW")

sys.stderr.write("reading file\n")

# parse one line at a time

for line in f:

	# the headword is separated from part of speech by a double space
	
	head_right = line.find("  ")
	
	head = line[:head_right]
	
	# squash case
	
	head = head.lower()
	
	# use only the first principal part
	
	head = re.split("[^a-z]+", head[1:])[0].strip()

	# the definition begins with ::

	def_left = line.find("::") + 2
			
	line = line[def_left:]
	
	# remove leading/trailing whitespace
	
	line = line.strip()
	
	# lowercase
	
	line = line.lower()
	
	# split into words on non-letter chars
	
	words = re.split('\W+', line)
		
	# count each word
	# if it's not already in the word count dictionary
	# it has to be added 
	
	for word in words:
	
		if word not in wc:
			wc.update({word: 1})
			
		else:
			wc[word] += 1
			
			
	#
	# check to see whether we've seen this word before
	#   if so, add this def to what we have already
	#   if not, add it as a separate entry 
	#      and add the head to the lookup table
	# 
	
	if head in lookup:
				
		corpus[lookup[head]].extend(words)
		full_def[lookup[head]] = full_def[lookup[head]] + " " + line
	
	else:
		corpus.append(words)
		full_def.append(line)
		headword.append(head)
		
		lineno = len(corpus) - 1
		lookup.update({head: lineno})
						
f.close()

# create a stoplist based on frequency

sys.stderr.write("calculating stoplist\n")

# words that only occur once can't add any co-occurrence information
# words that occur too frequently are probably not helpful either
# the upper bound could be adjusted later

stoplist = [word for word in wc.keys() if (wc[word] < 2) or (wc[word] > 550)]

# the "corpus" is just all the dictionary entries 
# with stopwords removed

# this takes a little while, so it makes sense to save the results

sys.stderr.write("removing stopwords from corpus\n")

# draw progress bar
pbar = ProgressBar(widgets=[Bar(), Percentage()], maxval=len(corpus)).start()

deleted = 0

for i, this_def in enumerate(corpus):
	
	# limit doc to words not in the stoplist

	corpus[i] = [word for word in this_def if word not in stoplist]
	
	# delete entries which have no words left
	
	if len(corpus[i]) < 1:
		del corpus[i]
		del headword[i]
		del full_def[i]
		
		deleted = deleted + 1
	
	pbar.update(i+1)

pbar.finish()

sys.stderr.write("{0} headwords deleted because the entry consisted entirely of stopwords\n".format(deleted))

# redo the lookup table to account for deletions

lookup=dict()

for i, head in enumerate(headword):
	
	lookup.update({head: i})
	

# save the files

sys.stderr.write("saving\n")

f = open(path_data + "/whitaker.corpus.pickle", "w")
pickle.dump(corpus, f)
f.close

f = open(path_data + "/whitaker.full_defs.pickle", "w")
pickle.dump(full_def, f)
f.close

f = open(path_data + "/whitaker.headword.pickle", "w")
pickle.dump(headword, f)
f.close

f = open(path_data + "/whitaker.lookup.pickle", "w")
pickle.dump(lookup, f)
f.close

# dump the stoplist to stdout

sys.stderr.write("dumping stoplist\n")

for count, word in sorted(zip([wc[w] for w in stoplist], stoplist)):
	
	print "{0}\t{1}".format(count, word)
	