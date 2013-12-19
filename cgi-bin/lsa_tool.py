#!/usr/bin/env python

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

form = cgi.FieldStorage() 
args_c = form.getvalue('dropdown')
args_s = "/var/www/tesserae/texts/lsa/stoplist_250.txt"
args_q = form.getvalue('query')
args_i = form.getvalue('query_id')
args_d = form.getvalue('num_topics')
args_m = "/var/www/tesserae/texts/lsa/aeneid.map"

# if provided, include a mapping to original text and score
map = {};
if args_m != "":
   f = open(args_m)
   raw_map = f.read().splitlines()

   for entry in raw_map:
      fields = entry.split('\t')
      data_string = ""
      data_string += fields[1]
      data_string += " "
      data_string += fields[2]
      map[fields[0]] = data_string 

# read in raw files
documents = []
filename_map = {};
listing = os.listdir("/var/www/tesserae/texts/lsa/" + args_c)
counter = 0
for infile in sorted(listing):
   f = open(os.path.join("/var/www/tesserae/texts/lsa/" + args_c, infile))
   documents.append(f.read())
   fields = infile.split('.')
   filename_map[counter] = int(fields[0])
   counter += 1

# remove common words and tokenize
f = open(args_s)
stoplist = f.read().splitlines()
texts = [[word for word in document.lower().split() if word not in stoplist]
          for document in documents]

# remove words that appear only once
all_tokens = sum(texts, [])
tokens_once = set(word for word in set(all_tokens) if all_tokens.count(word) == 1)
texts = [[word for word in text if word not in tokens_once]
         for text in texts]

dictionary = corpora.Dictionary(texts)

# print dictionary.token2id

corpus = [dictionary.doc2bow(text) for text in texts]

lsi = models.LsiModel(corpus, id2word=dictionary, num_topics=args_d)

if not args_q is not None:
   query_file = args_i + '.txt'
   f = open(os.path.join('/var/www/tesserae/texts/lsa/lucan.bellum_civile.part.1', query_file))
   doc = f.read()
else:
   doc = args_q

vec_bow = dictionary.doc2bow(doc.lower().split())
vec_lsi = lsi[vec_bow] # convert the query to LSI space
# print vec_lsi

index = similarities.MatrixSimilarity(lsi[corpus])

sims = index[vec_lsi] 
sims = sorted(enumerate(sims), key=lambda item: -item[1])
counter = 1

print "Content-type:text/html\r\n\r\n"
print "<html>"
print "<head>"
print "<title>Experimental - Results</title>"
print "</head>"
print "<body>"

for result in sims:
   (x, y) = result
   # print x, " ", y
   # print documents[x], " ", y

   verbose = ""
   if args_m != "" and str(x) in map:
      verbose = map[str(filename_map[x])]

   print  counter, filename_map[x], verbose, y, "<br><br>"
   counter += 1

print "</body>"
print "</html>"
