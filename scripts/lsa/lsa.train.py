#!/usr/bin/env python
'''perform the training stage of lsa search'''

def read_pointer():
	'''look for .tesserae.conf; return lib path'''
	
	dir = os.path.dirname(sys.argv[0])
	lib = None
	pointer = os.path.join(dir, '.tesserae.conf')

	while not os.access(pointer, os.R_OK):
		
		if dir == os.path.sep:
			raise LookupError('file not found: {0}'.format(pointer))
			return lib
			
		dir = os.path.dirname(dir)
		pointer = os.path.join(dir, '.tesserae.conf')
		
	f = open(pointer, 'r');
	
	lib = f.readline().strip()
	
	return lib

def main():
				
	#
	# check for options
	#
	
	parser = argparse.ArgumentParser(
				description='Create LSA training samples from a corpus')
	parser.add_argument('files', metavar='FILES', type=str, nargs='+')
	parser.add_argument('--lang', metavar='LANG', type=str, default='la',
				help='language')
	parser.add_argument('-n', '--stop', metavar='N', type=int, default=250,
				help='number of stop words')
	parser.add_argument('-q', '--quiet', action='store_const', const=1,
				help='print less info')

	opt = parser.parse_args()
	
	#
	# read files given as cmd line args
	#
	
	sources = []
	
	for file in opt.files:
	
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
	
		file_stoplist = os.path.join(fs['data'], 'common', opt.lang + '.stem.freq')
		dir_source   = os.path.join(fs['data'], 'lsa', opt.lang, source)
	
		# read in sample files
	
		print "reading " + source
		
		documents = []
		
		listing = os.listdir(os.path.join(dir_source, 'source'))
		listing = [sample for sample in listing if not sample.startswith('.')]
		
		for sample in sorted(listing):
		   f = open(os.path.join(dir_source, 'source', sample))
		   documents.append(f.read())
		
		# load stop list, hapax legomena
		
		print " - loading stop list of {0} words".format(opt.stop)
		
		f = open(file_stoplist)
		
		stoplist  = []
		
		for i, rec in enumerate(f.read().splitlines()):
		
			if rec.startswith('#'):
				continue
		
			form, count = rec.split()
		
			if i < opt.stop: 
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

#
# stuff to execute
#

import string
import os
import os.path
import sys
import argparse

sys.path.append(read_pointer())
from tesserae import fs, url

from gensim import corpora, models, similarities

if __name__ == '__main__':
    main()
