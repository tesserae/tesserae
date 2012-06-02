#! /opt/local/bin/python

import re
import sys
import pickle

# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# load the data

path_data = "/Volumes/CWFDATA/semantics/"

print "loading original data"

f = open(path_data + "whitaker.full_defs.pickle", "r")
full_def = pickle.load(f)
f.close

f = open(path_data + "whitaker.lookup.pickle", "r")
lookup = pickle.load(f)
f.close

f = open(path_data + "whitaker.headword.pickle", "r")
headword = pickle.load(f)
f.close


print "loading saved dictionary"

dictionary = corpora.Dictionary.load(path_data + "whitaker.dict")

print "loading saved corpus"

corpus = corpora.MmCorpus(path_data + "whitaker.mm")

print "loading saved tfidf model"

tfidf = models.TfidfModel.load(path_data + "model.whitaker.tfidf")

print "creating tfidf wrapper for corpus"

corpus_tfidf = tfidf[corpus]

print "loading saved lsi model"

lsi = models.LsiModel.load(path_data + "model.whitaker.lsi")

print "creating lsi wrapper for corpus"

corpus_lsi = lsi[corpus_tfidf]

print "exporting lsi representation"

f = open(path_data + "whitaker.lsi-table.txt", "w")

for i, doc in enumerate(corpus):
 	
 	head = headword[i]
 	
	# set every column to 0 initially

 	cols = [0.0 for j in range(300)]

	for x, y in lsi[doc]:
		
		cols[x] = round(y, 5)

 	f.write(head + "\t" + "\t".join([str(i) for i in cols]) + "\n")
	
f.close()