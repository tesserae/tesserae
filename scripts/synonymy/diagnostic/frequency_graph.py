#!/usr/bin/env python
"""
Does something.

Longer description of what this program does.
"""

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

import pickle
import os.path
import codecs
import unicodedata
import re

#
# global variables
#

freq = {}
rank = {}
trans = {}

number = re.compile(r'[0-9]', re.U)

#
# functions
#

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
	freq = []
	n = 0
	
	for line in f:
		lemma, count = line.split('\t')
		
		lemma = tesslang.standardize(lang, lemma)
		lemma = number.sub('', lemma)
		
		freq.append(float(count)/total)
		rank[lemma] = len(freq) - 1
		
		pr.advance(len(line.encode('utf-8')))
	
	return(freq, rank)


def parse_trans(feature, quiet):
	'''read the generated translation dictionary'''
	
	filename = os.path.join(fs['data'], 'synonymy', feature + '.csv')
	
	try: 
		f = codecs.open(filename, encoding='utf_8')
	except IOError as err:
		print "Can't read {0}: {1}".format(filename, str(err))
		sys.exit(1)
	
	if not quiet:
		print 'Reading {0}'.format(filename)
	
	trans = dict()
	
	for line in f:
		line = line.strip()
		field = line.split(',')
		
		trans[field[0]] = field[1:]
		
	return(trans)


def export_links_by_rank(filename, quiet):
	'''print pairwise links replacing nodes with their frequencies'''
	try:
		f = open(filename, 'w')
	except IOError as err:
		print "Can't read {0}: {1}".format(filename, str(err))
		sys.exit(1)
	
	if not quiet:
		print 'Writing {0}'.format(filename)
	
	for head in trans:
		if head in rank['grc']:
			for tran in trans[head]:
				if tran in rank['la']:
					f.write('{0}\t{1}\n'.format(rank['grc'][head], rank['la'][tran]))
	
	f.close()


def export_frequencies(lang, name, quiet):
	'''print the frequency distributions of stems in the two languages'''
		
	filename = lang + '.' + name
	
	try:
		f = open(filename, 'w')
	except IOError as err:
		print "Can't read {0}: {1}".format(filename, str(err))
		sys.exit(1)
		
	if not quiet:
		print 'Writing {0}'.format(filename)
		
	for i in range(len(freq[lang])):
		f.write('{0}\t{1}'.format(i, freq[lang][i]))
		f.write('\n')
	
	f.close()


#
# main
#

def main():
	
	#
	# check for options
	#
	
	parser = argparse.ArgumentParser(
			description='Do something')
	parser.add_argument('-q', '--quiet', action='store_const', const=1,
			help = "Don't print status messages")
	
	opt = parser.parse_args()
	
	#
	# init global vars
	#
	
	global freq
	global rank
	global trans
	
	#
	# load stoplist
	#
	
	for lang in ['grc', 'la']:
		freq[lang], rank[lang] = parse_stop_list(lang, '*', opt.quiet)
		
		export_frequencies(lang, 'freq_distr', opt.quiet)
	
	#
	# load translation data 
	#
	
	trans = parse_trans('trans2m', opt.quiet)
	
	#
	# print output
	#
	
	export_links_by_rank('links_by_rank', opt.quiet)
	

if __name__ == '__main__':
    main()
