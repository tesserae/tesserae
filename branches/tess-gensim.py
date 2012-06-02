# import regular expression module

import re

# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# set the text path

fs_text = "/Users/chris/tesserae/texts/la"
fs_data = "/Volumes/CWFDATA/semantics"

# this will be our corpus

samples = []

# open the file, create a file object

f = open(fs_text + "/vergil.aeneid.tess")

print "reading file"

# parse one line at a time

for line in f:

	# assume the line tag ends with the first >\t sequence

	tag_limit = line.find('>\t')
	
	# if that doesn't occur, go on to the next line
	
	if tag_limit < 0: 
		continue
		
	else:
		tag_limit = tag_limit + 2
	
	# skip everything to the left of that point
	
	line = line[tag_limit:]
	
	# remove leading/trailing whitespace
	
	line = line.strip()
	
	# lowercase
	
	line = line.lower()
	
	# split into tokens on non-letter chars
	
	words = re.split('[^a-z]+', line)
	
	# remove empty words
	
	if words[-1] == "" : del words[-1]
	
	# add this line to the corpus as a new doc
	
	samples.append(words)
	
f.close()

#
# this bit is copied from 
#    http://radimrehurek.com/gensim/tut1.html
#

# remove words that appear only once

print "removing hapax legomena"

all_tokens = sum(samples, [])

tokens_once = set(word for word in set(all_tokens) 
			if all_tokens.count(word) == 1)

corpus = [[word for word in sample if word not in tokens_once]
			for sample in samples]

# create dictionary

print "creating dictionary"

dictionary = corpora.Dictionary(samples)
dictionary.save(fs_data + "/aeneid.dict")

# convert each sample to a bag of words

print "converting each sample to bag-of-words"

corpus = [dictionary.doc2bow(sample) for sample in samples]

corpora.MmCorpus.serialize(fs_data + "/aeneid.mm", corpus)

#
# this bit is copied from
# 	http://radimrehurek.com/gensim/tut2.html
#

print "creating tfidf model"

tfidf = models.TfidfModel(corpus)

tfidf.save(fs_data + "/model.tfidf")

print "transforming the corpus to tfidf"

corpus_tfidf = tfidf[corpus]

print "creating lsi model"

lsi = models.LsiModel(corpus_tfidf, id2word=dictionary, num_topics=300)

lsi.save(fs_data + "/model.lsi")

print "transforming the corpus to lsi"

corpus_lsi = lsi[corpus_tfidf]

#
# print out the topics
#

lsi.show_topics()
