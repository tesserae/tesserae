#! /opt/local/bin/python

import re
import sys
import pickle

# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# load the data:

path_data = "/Volumes/CWFDATA/semantics/"

# the english definitions

f = open(path_data + "whitaker.full_defs.pickle", "r")
full_def = pickle.load(f)
f.close

# the headwords

f = open(path_data + "whitaker.headword.pickle", "r")
headword = pickle.load(f)
f.close

# headword lookup table

f = open(path_data + "whitaker.lookup.pickle", "r")
lookup = pickle.load(f)
f.close

# the table of classifications

# syn is a list of lists

syn = []
for i in range(1000):
	
	syn.append([])


# read the table from the file

f = open(path_data + "whitaker.classes.txt", "r")

# skip the header line

f.readline()

# now read each line of the table

for line in f:
	
	line = line.strip()
	
	# split the line in two on the righthand quotation mark and space
	
	head, sclass = line.split('" ')
	
	# remove the lefthand quotation mark
	
	head = head[1:]
	
	# now add to the syn table

	syn[int(sclass)-1].append(head)
	
f.close()

#
# now print a list of classes with their members
#

# create an html frame

htmlopen = """
<html>
<head><title>Synonym classes</title></head>
<body>
   <h1>test results &mdash; 1000 synonym classes &mdash; whitaker's words</h1>
"""

htmlclose = """
</body>
</html>
"""

# prepare an html file for output

f = open("data/whitaker.classes.html", "w")

f.write(htmlopen)

# each line will be come a table

for sclass, words in enumerate(syn):
	
	# the table head
	
	f.write("<table>\n")
	f.write('  <tr><th colspan="2">Class {0}</th></tr>\n'.format(sclass+1))
	
	# create the rows
	
	row = []
	
	for word in words:
		
		this_def = full_def[lookup[word]]
		
		row.append("<tr><td>{0}</td><td>{1}</td></tr>\n".format(word, this_def))
	
	f.writelines(row)
	
	f.write("</table>\n\n")
	
f.write(htmlclose)

f.close()