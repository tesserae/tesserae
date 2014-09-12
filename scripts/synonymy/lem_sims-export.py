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
import re
import math

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
	
	return(lib)

sys.path.append(read_pointer())

from TessPy.tesserae import fs, url
from TessPy import progressbar
from TessPy import tesslang

from gensim import corpora, models, similarities

#
# global variables
#

by_word  = {}
corpus   = []
by_id    = []
index    = []
full_def = {}
rank     = {}

number = re.compile(r'[0-9]', re.U)

#
# functions
#

def get_results(q):
	"""test query q against the similarity matrix"""
				
	q_id = by_word[q]
					
	sims = index[corpus[q_id]]
	
	for i in range(0,len(sims)):
		r_id, score = sims[i]
		
		r = by_id[r_id]
		
		sims[i] = (r, score)
		
	return(sims)


def filter_results(sims, q, mode):
	'''filter out query stem and optionally query language'''
	
	ok = []
	
	for pair in sims:	
		r, score = pair
		
		# results to skip: 
		#	- wrong language, or
		#   - result == query
		
		if mode > 0:
			if is_greek(r) != (mode - 2):
				continue
#		else:
#			if r == q:
#				continue
		
		ok.append(pair)
	
	return(ok)


def apply_freq_diff(sims, q):
	'''discount scores according to rank difference between q and r'''
	
	for i in range(0, len(sims)):
		r, score = sims[i]
		
		score = score - math.fabs(rank[q] - rank[r])/10
		
		sims[i] = (r, score)
	
	return(sims)	

def cull(sims, n, c):
	'''sort results, take either top n or all above score cutoff c'''
		
	sims = sorted(sims, key=lambda item: -item[1])
		
	if c is not None:
		ok = []

		for pair in sims:
			r, score = pair
			
			if score < c:
				break
		
			ok.append(pair)
		
		sims = ok

	if len(sims) > n:
		sims = sims[:n]

	return(sims)

def export_row(file, q, sims):
	'''write a row to the output file'''
	
	row = [q]
	
	for pair in sims:
		r, score = pair
		
		row.append(r)
	
	if file is not None:
		file.write(u','.join(row) + '\n')
	else:
		print u','.join(row)


def parse_stop_list(lang, name, quiet):
	'''read frequency table'''
	
	# open stoplist file
	
	filename = None
	
	if name == '*':
		filename = os.path.join(fs['data'], 'common', lang + '.stem.freq')
	else:
		filename = os.path.join(fs['data'], 'v3', lang, name, name + '.freq_stop_stem')
		
	if not quiet:
		print 'Reading stoplist {0}'.format(filename)
		
	pr = progressbar.ProgressBar(os.stat(filename).st_size, quiet)
	
	try: 
		f = codecs.open(filename, encoding='utf_8')
	except IOError as err:
		print "Can't read {0}: {1}".format(filename, str(err))
		sys.exit(1)
		
	# read stoplist header to get total token count
	
	head = f.readline()
	
	m = re.compile('#\s+count:\s+(\d+)', re.U).match(head)
	
	if m is None:
		print "Can't find header in {0}".format(filename)
		sys.exit(1)
		
	total = int(m.group(1))
	
	pr.advance(len(head.encode('utf-8')))
	
	# read the individual token counts, divide by total
	
	rank = {}
	n = 1
	
	for line in f:
		lemma, count = line.split('\t')
		
		lemma = tesslang.standardize(lang, lemma)
		lemma = number.sub('', lemma)
		
		rank[lemma] = math.log(n)
		
		n += 1
		
		pr.advance(len(line.encode('utf-8')))
		
	return(rank)


def load_dict(filename, quiet):
	'''load a dictionary previously saved with pickle'''
	
	file_dict = os.path.join(fs['data'], 'synonymy', filename)
	
	if not quiet:
		print 'Reading ' + file_dict
		
	f = open(file_dict, 'r')
	
	dict_ = pickle.load(f)
	
	f.close()
	
	return(dict_)


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
			help = 'Similarity threshold for synonymy (range: 0-1)')
	parser.add_argument('-w', '--weighted', action='store_const', const=1,
			help = 'Weight results by rank difference from query')
	parser.add_argument('-q', '--quiet', action='store_const', const=1,
			help = "Don't print status messages to stderr")
		
	opt = parser.parse_args()
	
	if opt.translate not in [1, 2]:
		opt.translate = 0
			
	#
	# load data created by read_lexicon.py
	#
		
	# the text-only defs
		
	# global full_def
	# 
	# full_def = load_dict('full_defs.pickle', opt.quiet)
			
	# the index by word
	
	global by_word
	
	by_word = load_dict('lookup_word.pickle', opt.quiet)
	
	# the index by id
	
	global by_id
	
	by_id = load_dict('lookup_id.pickle', opt.quiet)
		
	# the corpus
	
	global corpus
	
	if opt.lsi is None:
		file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_tfidf.mm')
	else:
		file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_lsi.mm')
	
	if not opt.quiet:
		print 'Loading corpus ' + file_corpus
	
	corpus = corpora.MmCorpus(file_corpus)
	
	# the similarities index
	
	global index
	
	file_index = os.path.join(fs['data'], 'synonymy', 'gensim.index')
	
	if not opt.quiet:		
		print 'Loading similarity index ' + file_index
	
	index = similarities.Similarity.load(file_index)

	# optional: consider frequency distribution
	
	global rank
	
	if opt.weighted == 1:
		rank = dict(parse_stop_list('la', '*', opt.quiet), **parse_stop_list('grc', '*', opt.quiet))

	#
	# determine translation candidates, write output
	#
	
 	if not opt.quiet:
		print 'Exporting dictionary'
	
	filename_csv = os.path.join(fs['data'], 'synonymy', opt.feature + '.csv')
	
	file_output = codecs.open(filename_csv, 'w', encoding='utf_8')
	
	pr = progressbar.ProgressBar(len(by_word), opt.quiet)
		
	# take each headword in turn as a query
	
	for q in by_word:
		pr.advance()
		
		if opt.translate and (is_greek(q) == opt.translate - 1):
			continue
			
		if (q not in by_word):
			continue
			
		# query the similarity matrix
		
		sims = get_results(q)
		
		# filter out query word, query language
		
		sims = filter_results(sims, q, opt.translate)
		
		# optional: apply distribution difference metric
		
		if opt.weighted == 1:
			sims = apply_freq_diff(sims, q)
			
		# keep only the best results, top n or above cutoff
		
		sims = cull(sims, opt.results, opt.cutoff)
		
		# print row
		
		export_row(file_output, q, sims)


if __name__ == '__main__':
    main()
