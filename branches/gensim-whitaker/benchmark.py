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
# read the benchmark data
#

print "\\begin{table}"
print "\\caption{benchmark words with synonyms from D\"{o}derlein}"
print "\\vspace{.25in}"
print "\\begin{tabular}{ll}"

syndict = dict()

f = open("temp-benchmark.txt", "r")

for line in f:
	
	test = re.search(r"Page (\d+)", line)
	if test:
		pageno = test.group(1)
		
	test = re.search(r"How many entries? (\d+)", line)
	if test:
		entryno = test.group(1)
		
	test = re.search(r"Headword:([a-z]+)", line)
	if test:
		headword = test.group(1)
		
	test = re.search(r"Synonyms:(.+)", line)
	if test:
		synonyms = test.group(1).strip().split()
		syndict.update({headword : synonyms})

		print "\\textbf{" + headword + "} & " + ", ".join(synonyms) + "\\\\"

print "\\end{tabular}"
print "\\end{table}"
print
print

#
# test all the benchmark words
#

for lookupword in sorted(syndict.keys()):

	# get the line number of this word in Whitaker

	lineno = lookup[lookupword]
	
	# parse the entry

	# entry_head, entry_body = full_def[lineno].split(" :: ")
	# 
	# entry_code = entry_head[-7:]
	# entry_head = entry_head[:-7].strip()
	# entry_head, entry_pos = entry_head.split("  ")
	# entry_head = entry_head[1:]
	# entry_head = re.split("[^a-zA-Z]", entry_head)[0]
	# 
	# entry_body = entry_body.strip()

	# print the top part of the table

	print "\\begin{sidewaystable}"
	print "\\caption{\\textbf{" + lookupword + "} : " + ", ".join(syndict[lookupword]),
	print "\\label{" + lookupword + "}}"
	print "\\vspace{.25in}"
	print "\\begin{tabular}{l|lll}"

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
	
		print "   {0} & {1} & {2} & {3}\\\\".format(score, this_head, this_pos, this_body)

		# print the bottom of the table

	print "\\end{tabular}"
	print "\\end{sidewaystable}"
	print
	print