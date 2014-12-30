#!/usr/bin/env python
"""
Parse the big XML dictionaries from Perseus (modified by James Gawley)

This script looks for XML versions of Liddell-Scott-Jones and
Lewis & Short, at dict/grc.lexicon.xml and dict/la.lexicon.xml,
respectively.  It parses each dictionary into headwords and 
English definitions.

This version of read_lexicon has been modified to compare latin-to-latin and
to include the word itself as the first viable match.

"""

import sys
import re
import os.path
import codecs
import pickle
import argparse
import unicodedata

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

#from stemming.porter2 import stem
from gensim import corpora, models, similarities

#
# a collection of compiled regular expressions
#

class pat:
	'''Useful regular expressions'''
	
	# lexicon entry
	
	entry = re.compile(r'<entryFree [^>]*key="(.+?)"[^>]*>(.+?)</entryFree>')
	
	# XML nodes to omit
	
	stop = [
		re.compile(pat, re.U) for pat in [
			r'<cit>.*?</cit>',
			r'<bibl .+?>.*?</bibl>',
			r'<orth .+?>.*?</orth>',
			r'<etym .+?>.*?</etym>',
			r'<itype .+?>.*?</itype>',
			r'<pos .+?>.*?</pos>',
			r'<number .+?>.*?</number>',
			r'<gen .+?>.*?</gen>',
			r'<mood .+?>.*?</mood>',
			r'<case .+?>.*?</case>',
			r'<tns .+?>.*?</tns>',
			r'<per .+?>.*?</per>',
			r'<pron .+?>.*?</pron>',
			r'<date>.*?</date>',
			r'<usg .+?>.*?</usg>',
			r'<gramGrp .+?>.*?</gramGrp>'
		]
	]
	
	# language-specific regular expressions matching the parts of
	# dictionary entries that are English definitions of the headword
	
	definition = {
		'la': re.compile(r'<hi [^>]*rend="ital"[^>]*>(.+?)</hi>', re.U),
		'grc': re.compile(r'<tr\b[^>]*>(.+?)</tr>', re.U)
	}
	
	# betacode greek tag
	# note that both dictionaries use <foreign lang="greek">
	# while neither uses <foreign> for any other language
	# (inside definitions, anyway)
	
	foreign = re.compile(r'<foreign lang="greek">(.+?)</foreign>', re.U)
	
	# stuff to remove from english entries
	
	clean = {
		'any': re.compile(r'\W+', re.U),
		'la': re.compile(r'[^a-z]', re.U),
		'grc': re.compile(r'[\^_]', re.U)
	}
	
	number = re.compile(r'[0-9]', re.U)


def mo_beta2uni(mo):
	'''A wrapper for tesslang.beta_to_uni that takes match objects'''
	
	return(tesslang.beta_to_uni(mo.group(1)))


def write_dict(defs, name, quiet):
	'''Save a copy of the dictionary in pickle format'''
	
	f = open(os.path.join(fs['data'], 'synonymy', name + '.pickle'), 'w')
		
	if not quiet:
		print "Saving dictionary to {0}".format(f.name)
		
	pickle.dump(defs, f)
	
	f.close()


def read_dict(name, quiet):
	'''Load a copy of the dictionary in pickle format'''
	
	f = open(os.path.join('data', 'synonymy', name + '.pickle'), 'r')
		
	if not quiet:
		print "Loading dictionary from {0}".format(f.name)
		
	defs = pickle.load(f)
	
	return(defs)


def parse_XML_dictionaries(langs, quiet):
	'''Create a dictionary of english translations for each lemma'''
		
	defs = dict()
	
	# process latin, greek lexica in turn
	
	for lang in langs:
		filename = os.path.join(fs['data'], 'common', lang + '.lexicon.xml')
		
		if not quiet:
			print 'Reading lexicon {0}'.format(filename)
		
		pr = progressbar.ProgressBar(os.stat(filename).st_size, quiet)
		
		try: 
			f = codecs.open(filename, encoding='utf_8')
		except IOError as err:
			print "Can't read {0}: {1}".format(filename, str(err))
			sys.exit(1)
		
		#
		# Each line in the lexicon is one entry.
		# Process one at a time to extract headword, definition.
		#
				
		for line in f:
			pr.advance(len(line.encode('utf-8')))
			
			# skip lines that don't conform with the expected entry structure
						
			m = pat.entry.search(line)
			
			if m is None:
				continue
			
			lemma, entry = m.group(1, 2)
			
			# standardize the headword
			
			lemma = pat.clean[lang].sub('', lemma)
			lemma = pat.number.sub('', lemma)
			lemma = tesslang.standardize(lang, lemma)
						
			# remove elements on the stoplist
			
			for stop in pat.stop:
				entry = stop.sub('', entry)
						
			# transliterate betacode to unicode chars
			# in foreign tags
			
			entry = pat.foreign.sub(mo_beta2uni, entry)
												
			# extract strings marked as translations of the headword
			
			def_strings = pat.definition[lang].findall(entry)
			
			# drop empty defs
			
			def_strings = [d for d in def_strings if not d.isspace()]
									
			# skip lemmata for which no translation can be extracted
			
			if def_strings is None:
				continue
							
			if lemma in defs and defs[lemma] is not None:					
				defs[lemma].extend(def_strings)
			else:
				defs[lemma] = def_strings
		
	if not quiet:
		print 'Read {0} entries'.format(len(defs))
		print 'Flattening entries with multiple definitions'
	
	pr = progressbar.ProgressBar(len(defs), quiet)
	
	empty_keys = set()
	
	for lemma in defs:
		pr.advance()
		
		if defs[lemma] is None or defs[lemma] == []:
			empty_keys.add(lemma)
			continue
		
		defs[lemma] = '; '.join(defs[lemma])
	
	if not quiet:
		print 'Lost {0} empty definitions'.format(len(empty_keys))

	for k in empty_keys:
		del defs[k]

	return(defs)


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
	
	freq = dict()
	
	for line in f:
		
		lemma, count = line.split('\t')
		
		lemma = tesslang.standardize(lang, lemma)
		lemma = pat.number.sub('', lemma)
		
		freq[lemma] = float(count)/total
		
		pr.advance(len(line.encode('utf-8')))
	
	return(freq)


def parse_stem_dict(lang, quiet):
	'''parse the csv stem dictionaries of Helma Dik'''
	
	filename = os.path.join(fs['data'], 'common', lang + '.lexicon.csv')
	
	f = open(filename, 'r')
	
	if not quiet:
		print 'Reading lexicon {0}'.format(filename)
	
	pr = progressbar.ProgressBar(os.stat(filename).st_size, quiet)
	
	try: 
		f = codecs.open(filename, encoding='utf_8')
	except IOError as err:
		print "Can't read {0}: {1}".format(filename, str(err))
		sys.exit(1)
		
	pos = dict()
	heads = dict()
	
	for line in f:
		pr.advance(len(line.encode('utf-8')))
		
		line = line.strip().lower().replace('"', '')
		
		try:
			token, code, lemma = line.split(',')
		except ValueError:
			continue
			
		lemma = tesslang.standardize(lang, lemma)
		lemma = pat.number.sub('', lemma)
		
		if len(code) == 10:	
			if lemma in pos:
				pos[lemma].append(code[:2])
			else:
				pos[lemma] = [code[:2]]
				
		heads[lemma] = 1
		
	success = 0
	
	for lemma in heads:
		if lemma in pos:
			success += 1
			
	print 'pos success; {0}%'.format(100 * success / len(heads))
	
	return(pos)


def bag_of_words(defs, stem_flag, quiet):
	'''convert dictionary definitions into bags of words'''
	
	# convert to bag of words, count words
	
	if not quiet:
		print "Converting defs to bags of words"
	
	count = {}
	
	pr = progressbar.ProgressBar(len(defs), quiet)
	
	empty_keys = set()
	
	for lemma in defs:
		pr.advance()
		
		defs[lemma] = [tesslang.standardize('any', w) 
							for w in pat.clean['any'].split(defs[lemma]) 
							if not w.isspace() and w != '']
				
		if len(defs[lemma]) > 0:
			for d in defs[lemma]:
				if d in count:
					count[d] += 1
				else:
					count[d] = 1
		else:
			empty_keys.add(lemma)
	
	if not quiet:
		print "Removing hapax legomena"
	
	pr = progressbar.ProgressBar(len(defs), quiet)
	
	for lemma in defs:
		pr.advance()
		
		defs[lemma] = [w for w in defs[lemma] if count[w] > 1]
		
		if defs[lemma] == []:
			empty_keys.add(lemma)
	
	if not quiet:
		print 'Lost {0} empty definitions'.format(len(empty_keys))
		
	for k in empty_keys:
		del defs[k]
	
	return(defs)


def build_corpus(defs, quiet):
	'''Create a "corpus" of the type expected by Gensim'''
	
	if not quiet:
		print 'Generating Gensim-style corpus'
	
	pr = progressbar.ProgressBar(len(defs), quiet)
	
	corpus = []
	
	for lemma in defs:
		pr.advance()
		
		corpus.append(defs[lemma])
	
	return(corpus)


def make_index(defs, quiet):
	'''Create two look-up tables: one by id and one by headword'''
	
	if not quiet:
		print 'Creating indices'
		
	by_word = {}
	by_id = []
	
	pr = progressbar.ProgressBar(len(defs), 1)
		
	for lemma in defs:
		pr.advance()
		
		by_id.append(lemma)
		by_word[lemma] = len(by_id) - 1
	
	# save the lookup table
	
	file_lookup_word = os.path.join(fs['data'], 'synonymy', 'lookup_word.pickle')
	
	if not quiet:
		print 'Saving index ' + file_lookup_word
	
	f = open(file_lookup_word, "w")
	pickle.dump(by_word, f)
	f.close()
	
	# save the id lookup
	
	file_lookup_id = os.path.join(fs['data'], 'synonymy', 'lookup_id.pickle')
	
	if not quiet:
		print 'Saving index ' + file_lookup_id
	
	f = open(file_lookup_id, "w")
	pickle.dump(by_id, f)
	f.close()


def main():
	
	#
	# check for options
	#
	
	parser = argparse.ArgumentParser(
				description='Read dictionaries')
	parser.add_argument('-c', '--cache', action='store_const', const=1,
				help='Use cached version of dictionaries')
	parser.add_argument('-s', '--stem', action='store_const', const=1,
				help='Apply porter2 stemmer to definitions')
	parser.add_argument('-t', '--topics', metavar='N', type=int,
				help='Perform LSI with N topics')
	parser.add_argument('-q', '--quiet', action='store_const', const=1,
				help='Print less info')
	parser.add_argument('-m', '--match', choices=['tess','dik'], default=None,
				help = "Restrict candidates to Tesserae's stems or to Helma Dik's")
	parser.add_argument('-n', '--nsims', metavar='N', type=int,
				help = "Only calculate top N similarities")
	
	opt = parser.parse_args()
	quiet = opt.quiet
	
	#
	# read the dictionaries
	#
	
	if opt.cache == 1:
		defs = read_dict('full_defs', opt.quiet)
	else:
		defs = parse_XML_dictionaries(['la'], opt.quiet)
		write_dict(defs, 'full_defs', opt.quiet)
	
	# convert to bag of words
	
	defs = bag_of_words(defs, opt.stem, opt.quiet)
	
	# (optional) utilize information from stem dictionary
	
	stem_pos = dict()
	
	if opt.match == 'tess':
		# get part of speech data
		
 		freq = dict(parse_stop_list('la', '*', opt.quiet), **parse_stop_list('grc', '*', opt.quiet))
		
		write_dict(freq, 'freq', opt.quiet)
		
		# limit synonym dictionary to members of stem dictionary
		
		print 'restricting synonym dictionary to extisting stem index'
		
		lost_keys = []

		for lemma in defs:
			if lemma not in freq:
				lost_keys.append(lemma)
		
		for lemma in lost_keys:
			del defs[lemma]
		
	if opt.match == 'dik':
		# get part of speech data
		
		stem_pos = dict(parse_stem_dict('la', opt.quiet), **parse_stem_dict('grc', opt.quiet))
		
		write_dict(stem_pos, 'pos', opt.quiet)
		
		# limit synonym dictionary to members of stem dictionary
		
		print 'restricting synonym dictionary to extisting stem index'
		
		lost_keys = []
		
		for lemma in defs:
			if lemma not in stem_pos:
				lost_keys.append(lemma)
		
		for lemma in lost_keys:
			del defs[lemma]
	
	# write_dict(defs, 'bow_defs')
	
	if not opt.quiet:
		print '{0} lemmas still have definitions'.format(len(defs))
	
	# convert back into one string of defining words per lemma
	
	corpus = build_corpus(defs, opt.quiet)
	
	# create and save by-word and by-id lookup tables
	
	make_index(defs, opt.quiet)
		
	#
	# use gensim
	#
	
	# create dictionary
	
	if not opt.quiet:
		print 'Creating dictionary'
	
	dictionary = corpora.Dictionary(corpus)
	
	# save dictionary for debugging
	
	file_dictionary = os.path.join(fs['data'], 'synonymy', 'gensim.dictionary')
	
	if not opt.quiet:
		print 'Saving dictionary as ' + file_dictionary
		
	dictionary.save(file_dictionary)
	
	# convert each sample to a bag of words
	
	if not opt.quiet:
		print 'Converting each doc to bag-of-words'
	
	corpus = [dictionary.doc2bow(doc) for doc in corpus]
		
	# calculate tf-idf scores
	
	if not opt.quiet:
		print 'Creating tf-idf model'
	
	tfidf = models.TfidfModel(corpus)
		
	if not opt.quiet:
		print 'Transforming the corpus to tf-idf'
	
	corpus_tfidf = tfidf[corpus]
	
	# save corpus in market matrix format
	
	file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_tfidf.mm')
	
	if not opt.quiet:
		print 'Saving corpus as matrix ' + file_corpus
	
	corpora.MmCorpus.serialize(file_corpus, corpus_tfidf)
	
	# perform lsi transformation

	corpus_final = corpus_tfidf

	if opt.topics is not None and opt.topics > 0:
		if not opt.quiet:
			print 'Performing LSI with {0} topics'.format(opt.topics)
		
		lsi = models.LsiModel(corpus_tfidf, id2word=dictionary, num_topics=opt.topics)
		
		corpus_final = lsi[corpus_tfidf]

		# save corpus in market matrix format

		file_corpus = os.path.join(fs['data'], 'synonymy', 'gensim.corpus_lsi.mm')

		if not opt.quiet:
			print 'Saving corpus as matrix ' + file_corpus

		if opt.topics is not None and opt.topics > 0:
			corpora.MmCorpus.serialize(file_corpus, corpus_final)
	
	# calculate similarities

	if not opt.quiet:
		print 'Calculating similarities (please be patient)'
	
	dir_calc = os.path.join(fs['data'], 'synonymy', 'sims')
	
	index = similarities.Similarity(dir_calc, corpus_final, len(corpus_final), opt.nsims)
	
	file_index = os.path.join(fs['data'], 'synonymy', 'gensim.lemma.index')
	
	if not opt.quiet:
		print 'Saving similarity index ' + file_index
	
	index.save(file_index)


	
if __name__ == '__main__':
    main()
