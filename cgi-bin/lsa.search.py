#!/usr/bin/env python
'''run an lsa query'''

# modules necessary to read config file,
# parse command-line arguments

import os
import sys
import argparse

# read config

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

sys.path.append(read_pointer())


#
# Tesserae-specific modules
#

from TessPy.tesserae import fs, url
from TessPy import progressbar
from TessPy import tesslang

#
# additional modules for this script
#

import string
import logging
from gensim import corpora, models, similarities

#
# global variables
#


#
# functions
#


#
# main
#


def main():

	if 'REQUEST_METHOD' in os.environ:
		
		# print header
		
		print "Content-type:text/plain"
		print

	#
	# look for user options
	#
	
	parser = argparse.ArgumentParser(description='Do an LSA search on two Tesserae texts.')

	parser.add_argument('-c', '--corpus', required=True, help="text from which results are drawn")
	parser.add_argument('-q', '--query', required=True, help="text from which query is drawn")
	parser.add_argument('-l', '--lang',   type=str, default='la', help="language")
	parser.add_argument('-i', '--unit_id', type=int, default=0,  help="phrase id in the query text")
	parser.add_argument('-n', '--topics',  type=int, default=10, help="number of topics")

	args=parser.parse_args()
	
	# set paths
	
	dir_corpus = os.path.join(fs['data'], 'lsa', args.lang, args.corpus)
	dir_query = os.path.join(fs['data'], 'lsa', args.lang, args.query)

	#
	# load data from training program
	#
	
	logging.info("corpus=" + args.corpus)
	
	# dictionary
	
	file_dict = os.path.join(dir_corpus, 'dictionary')
	dictionary = corpora.Dictionary.load(file_dict)
	
	# corpus
	
	file_training = os.path.join(dir_corpus, 'training.mm')
	training = corpora.MmCorpus(file_training)
	
	# create lsi model
	
	lsi = models.LsiModel(training, id2word=dictionary, num_topics=args.topics)

	#
	# load query
	#
	
	logging.info("query=" + args.query + "; unit id=" + str(args.unit_id))
	
	listing = os.listdir(os.path.join(dir_query, 'small'))
	listing = [sample for sample in listing if not sample.startswith('.')]
        listing.sort()
	
	f = open(os.path.join(dir_query, 'small', listing[args.unit_id]))
	doc = f.read()

	vec_bow = dictionary.doc2bow(doc.lower().split())
	
	vec_lsi = lsi[vec_bow] # convert the query to LSI space

	#
	# calculate similarities
	#
	
	index = similarities.MatrixSimilarity(lsi[training])
	
	sims = index[vec_lsi] 
	sims = sorted(enumerate(sims), key=lambda item: -item[1])

	#
	# print results
	#
	
	for result in sims:
	   (x, y) = result
	
	   print  x, y
	
#
# call function main as default action
#

if __name__ == '__main__':
    main()
