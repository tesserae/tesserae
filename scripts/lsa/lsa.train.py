#!/usr/bin/env python
'''perform the training stage of lsa search'''

# modules necessary to read config file,
# parse command-line arguments

import os
import os.path
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
from gensim import corpora, models, similarities

#
# global variables
#


#
# functions
#

def loadStopList(filename, n):

	# load stop list, hapax legomena
	
	print " - loading stop list of {0} words".format(n)
	
	f = open(filename, 'r')
	
	stoplist  = []
	
	for i, rec in enumerate(f.read().splitlines()):
	
		if rec.startswith('#'):
			continue
	
		form = rec.split()[0]
	
		if i < n: 
			stoplist.append(form)
	
	return(stoplist)


#
# main
#

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

	# lsa-specific stoplist
	
	stoplist = loadStopList(os.path.join(fs['data'], 'common', opt.lang + '.lsa.stop'), opt.stop)
	
	#
	# read files given as cmd line args
	#
	
	names = []
	
	for file in opt.files:
	
		# strip path and extension to get file name
		
		if file.endswith('.tess'):
			names.append(os.path.basename(file)[0:-5])
		else:
			if os.path.isdir(file):
				for file_part in os.listdir(file):
					if file_part.endswith('.tess'):
						names.append(file_part[0:-5])
			continue
	
	# create LSI model from training set
	
	for name in names:
	
		dir_base  = os.path.join(fs['data'], 'lsa', opt.lang, name)
	
		# read in sample files
	
		print "reading " + name
		
		documents = []
		
		listing = os.listdir(os.path.join(dir_base, 'large'))
		listing = [sample for sample in listing if not sample.startswith('.')]
		
		for sample in sorted(listing):
		   f = open(os.path.join(dir_base, 'large', sample), 'r')
		   documents.append(f.read())
										
		# remove stop words and tokenize
		
		print " - removing stop words and hapax legomena"
		
		texts = [[word for word in document.lower().split() if word not in stoplist]
				  for document in documents]
		
		# build gensim dictionary
		
		print " - building dictionary"
		
		dictionary = corpora.Dictionary(texts)
		
		print " - exporting dictionary"
		
		file_dict = os.path.join(dir_base, 'dictionary')
		dictionary.save(file_dict)
		
		# build gensim corpus
		
		print " - converting to bag-of-words"
		
		training = [dictionary.doc2bow(text) for text in texts]
		
		# save corpus
		
		print " - exporting training set"
		
		file_training = os.path.join(dir_base, 'training.mm')
		corpora.MmCorpus.serialize(file_training, training)

#
# stuff to execute
#

if __name__ == '__main__':
    main()
