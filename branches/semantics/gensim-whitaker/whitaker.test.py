#! /opt/local/bin/python

import re
import sys
import pickle

# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# load the data

path_data = "/Users/chris/Dropbox/semantics/data/"

# print "loading original text file"

f = open(path_data + "whitaker.full_defs.pickle", "r")
full_def = pickle.load(f)
f.close

f = open(path_data + "lookup.pickle", "r")
lookup = pickle.load(f)
f.close

# print "loading saved dictionary"

dictionary = corpora.Dictionary.load(path_data + "whitaker.dict")

# print "loading saved corpus"

corpus = corpora.MmCorpus(path_data + "whitaker.mm")

# print "loading saved tfidf model"

tfidf = models.TfidfModel.load(path_data + "model.whitaker.tfidf")

# print "creating tfidf wrapper for corpus"

corpus_tfidf = tfidf[corpus]

# print "loading saved lsi model"

lsi = models.LsiModel.load(path_data + "model.whitaker.lsi")

# print "creating lsi wrapper for corpus"

corpus_lsi = lsi[corpus_tfidf]

# print "loading similarities matrix"

index = similarities.MatrixSimilarity.load(path_data + "whitaker.lsi.index")

#
# test a line
#

# get the line number from form

arg = sys.argv[1]
if arg in lookup:
	lineno = lookup[arg]
else:
	lineno = int(arg)

entry_head, entry_body = full_def[lineno].split(" :: ")

entry_code = entry_head[-7:]
entry_head = entry_head[:-7].strip()
entry_head, entry_pos = entry_head.split("  ")
entry_head = entry_head[1:]
entry_head = re.split("[^a-zA-Z]", entry_head)[0]

entry_body = entry_body.strip()

# print the top part of the table

print entry_head, 
print entry_pos, 
print entry_body

#
# get the most similar lines
#

query = lsi[corpus[lineno]]
sims = index[query]
sims = sorted(enumerate(sims), key=lambda item: -item[1])

for i, score in sims[0:24]:
	
	this_head, this_body = full_def[i].split(" :: ")
	this_code = this_head[-7:]
	this_head = this_head[:-7].strip()
	this_head, this_pos = this_head.split("  ")
	this_head = this_head[1:]
	this_head = re.split("[^a-zA-Z]", this_head)[0]
	this_body = this_body.strip()
	
	print score, 
	print this_head, 
	print this_pos, 
	print this_body

# print the bottom of the table

