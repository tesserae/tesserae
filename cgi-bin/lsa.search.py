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
import cgi, cgitb
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

	#
	# set params
	#
	
	target = 'lucan.bellum_civile.part.1'
	source = 'vergil.aeneid.part.1'
	lang   = 'la'
	
	unit_id  = 0
	topics   = 15
	
	#
	# look for user options
	#
	
	if 'REQUEST_METHOD' in os.environ:
	
		# web interface
	
		cgitb.enable()
		
		form = cgi.FieldStorage() 
		
		target  = form.getvalue('target', 'lucan.bellum_civile.part.1')
		source  = form.getvalue('source', 'vergil.aeneid.part.1')
		unit_id = int(form.getvalue('unit_id', 0))
		topics  = int(form.getvalue('num_topics', 15))
	
		# print header
		
		print "Content-type:text/plain"
		print

	else:
		
		# command line interface
	
		parser = argparse.ArgumentParser(description='Do an LSA search on two Tesserae texts.')
	
		parser.add_argument('-s', '--source', required=True, help="source text")
		parser.add_argument('-t', '--target', required=True, help="target text")
		parser.add_argument('-l', '--lang',   type=str, default='la', help="language")
		parser.add_argument('-i', '--unit-id', type=int, default=0,  help="phrase id in the target text")
		parser.add_argument('-n', '--topics',  type=int, default=15, help="number of topics")
	
		args=parser.parse_args()
	
		source  = args.source
		target  = args.target
		unit_id = args.unit_id
		topics  = args.topics
		lang    = args.lang
	
	# set paths
	
	dir_source = os.path.join(fs['data'], 'lsa', lang, source)
	dir_target = os.path.join(fs['data'], 'lsa', lang, target)

	#
	# load data from training program
	#
	
	logging.info("source=" + source)
	
	# dictionary
	
	file_dict = os.path.join(dir_source, 'dictionary')
	dictionary = corpora.Dictionary.load(file_dict)
	
	# corpus
	
	file_corpus = os.path.join(dir_source, 'corpus.mm')
	corpus = corpora.MmCorpus(file_corpus)
	
	# create lsi model
	
	lsi = models.LsiModel(corpus, id2word=dictionary, num_topics=topics)

	#
	# load query
	#
	
	logging.info("target=" + target + "; unit id=" + str(unit_id))
	
	listing = os.listdir(os.path.join(dir_target, 'target'))
	listing = [sample for sample in listing if not sample.startswith('.')]
	
	f = open(os.path.join(dir_target, 'target', listing[unit_id]))
	doc = f.read()
	
	vec_bow = dictionary.doc2bow(doc.lower().split())
	
	vec_lsi = lsi[vec_bow] # convert the query to LSI space

	#
	# calculate similarities
	#
	
	index = similarities.MatrixSimilarity(lsi[corpus])
	
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
