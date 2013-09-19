#!/usr/bin/env python
"""
Return the top similarity hits for query headwords

Prompts the user for query words.  The top n hits 
from the similarity matrix are returned to STDOUT.

Requires package 'gensim'.

See README.txt for workflow details.
"""

import pickle
import os
import sys
import codecs
import unicodedata
import argparse

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

from TessPy.tesserae import fs, url
from TessPy import progressbar
from TessPy import tesslang

from gensim import corpora, models, similarities

by_word  = dict()
corpus   = []
by_id    = []
index    = []
full_def = dict()


def get_results(q, n, c, file, filter):
	"""test query q against the similarity matrix"""
		
	row = [q]
		
	if (q in by_word):
		q_id = by_word[q]
						
		# query the similarity matrix
		
		sims = index[corpus[q_id]]
		sims = sorted(enumerate(sims), key=lambda item: -item[1])
				
		# filter results
		
		for pair in sims:	
			r_id, score = pair
			
			r = by_id[r_id]
			
			# results to skip: 
			#	- wrong language, or
			#   - result == query
			
			if filter:
				if is_greek(r) != (filter - 1):
					continue
			else:
				if r == q:
					continue
			
			# conditions to quit checking:
			#   - score below cutoff, or
			#   - top n already returned
			
			if c is not None:
				if score < c:
					break
				if len(row) > 12:
					break
			else:
				if len(row) > n:
					break
			
			row.append(r)
			
		if len(row) > 1:
										
			if file is not None:
				file.write(u','.join(row) + '\n')
			else:
				print u','.join(row)


def is_greek(form):
	'''try to guess whether a word is greek'''
	
	for c in form:
		if ord(c) > 255:
			return 1
	
	return 0


def main():
	
	#
	# check for options
	#
	
	parser = argparse.ArgumentParser(
			description='Query the headword similarities matrix')
	parser.add_argument('-n', '--results', metavar='N', default=2, type=int,
			help = 'Display top N results')
	parser.add_argument('-t', '--translate', metavar='MODE', default=1, type=int,
			help = 'Translation mode: 1=Greek to Latin; 2=Latin to Greek')
	parser.add_argument('-l', '--lsi', action='store_const', const=1,
			help = 'Use LSI to reduce dimensionality')
	parser.add_argument('-f', '--feature', metavar="FEAT", default='trans2', type=str,
			help = 'Name of feature dictionary to create')
	parser.add_argument('-c', '--cutoff', metavar='C', default=None, type=float,
			help = 'Similarity threshold for synonymy (range: 0-1).')
	
	opt = parser.parse_args()
	
	if opt.translate not in [1, 2]:
		opt.translate = 0
	
	quiet = 0
		
	#
	# read the text-only defs
	#
	
	file_dict = os.path.join(fs['data'], 'synonymy', 'full_defs.pickle')
	
	if not quiet:
		print 'Reading ' + file_dict

	f = open(file_dict, 'r')
	
	# store the defs
	
	global full_def
	
	full_def = pickle.load(f)
	
	f.close()
	
	#
	# load data created by calc-matrix.py
	#
		
	# the index by word
	
	global by_word
	
	file_lookup_word = os.path.join(fs['data'], 'synonymy', 'lookup_word.pickle')
	
	if not quiet:
		print 'Loading index ' + file_lookup_word
	
	f = open(file_lookup_word, 'r')
	by_word = pickle.load(f)
	f.close()
	
	# the index by id
	
	global by_id
	
	file_lookup_id = os.path.join(fs['data'], 'synonymy', 'lookup_id.pickle')
	
	if not quiet:
		print 'Loading index ' + file_lookup_id
	
	f = open(file_lookup_id, 'r')
	by_id = pickle.load(f)
	f.close()
	
	# the corpus
	
	global corpus
	
	if opt.lsi is None:
		file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_tfidf.mm')
	else:
		file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_lsi.mm')
	
	corpus = corpora.MmCorpus(file_corpus)
	
	# the similarities index
	
	global index
	
	file_index = os.path.join(fs['data'], 'synonymy', 'gensim.index')
	
	if not quiet:		
		print 'Loading similarity index ' + file_index
	
	index = similarities.Similarity.load(file_index)
	
 	if not quiet:
		print 'Exporting dictionary'
	
	filename_csv = os.path.join(fs['data'], 'synonymy', opt.feature + '.csv')
	
	file_output = codecs.open(filename_csv, 'w', encoding='utf_8')
	
	pr = progressbar.ProgressBar(len(by_word), quiet)
	
	# take each headword in turn as a query
	
	for q in by_word:
		pr.advance()
		
		q = unicodedata.normalize('NFC', q)
			
		if opt.translate and is_greek(q) == (opt.translate - 1):
			continue

		get_results(q, opt.results, opt.cutoff, file_output, opt.translate)


if __name__ == '__main__':
    main()
