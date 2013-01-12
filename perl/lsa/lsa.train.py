#!/usr/bin/python

#
# perform the training stage of lsa search
#

import string
import os
import sys
from gensim import corpora, models, similarities

# language of the source file

lang = 'la'

# number of stop words

n_stop = 250

# paths to local installation

fs_data = '/Users/chris/Sites/tesserae/data'
fs_text = '/Users/chris/Sites/tesserae/texts'

#
# read files given as cmd line args
#

sources = []

for file in sys.argv:

	# strip path and extension to get file name
	
	if file.endswith('.tess'):
		sources.append(os.path.basename(file)[0:-5])
	else:
		if os.path.isdir(file):
			for file_part in os.listdir(file):
				if file_part.endswith('.tess'):
					sources.append(file_part[0:-5])
		continue

for source in sources:

	file_stoplist = os.path.join(fs_data, 'common', lang + '.stem.freq')
	dir_source   = os.path.join(fs_data, 'lsa', lang, source)

	# read in sample files

	print "reading " + source
	
	documents = []
	
	listing = os.listdir(os.path.join(dir_source, 'source'))
	listing = [sample for sample in listing if not sample.startswith('.')]
	
	for sample in sorted(listing):
	   f = open(os.path.join(dir_source, 'source', sample))
	   documents.append(f.read())
	
	# load stop list, hapax legomena
	
	print " - loading stop list of " + str(n_stop) + " words"
	
	f = open(file_stoplist)
	
	stoplist  = []
	
	for i, rec in enumerate(f.read().splitlines()):
	
		form, count = rec.split()
	
		if i < n_stop: 
			stoplist.append(form)
			
		elif count == 1:
			stoplist.append(form)
	
	# remove stop words and tokenize
	
	print " - removing stop words and hapax legomena"
	
	texts = [[word for word in document.lower().split() if word not in stoplist]
			  for document in documents]
	
	# build gensim dictionary
	
	print " - building dictionary"
	
	dictionary = corpora.Dictionary(texts)
	
	print " - exporting dictionary"
	
	file_dict = os.path.join(dir_source, 'dictionary')
	dictionary.save(file_dict)
	
	# build gensim corpus
	
	print " - converting to bag-of-words corpus"
	
	corpus = [dictionary.doc2bow(text) for text in texts]
	
	# save corpus
	
	print " - exporting corpus"
	
	file_corpus = os.path.join(dir_source, 'corpus.mm')
	corpora.MmCorpus.serialize(file_corpus, corpus)
