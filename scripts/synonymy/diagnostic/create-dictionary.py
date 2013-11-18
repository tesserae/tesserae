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
import codecs
import shutil

#
# global variables
#


#
# functions
#

def read_dict(name, quiet):
	'''read the dictionary saved by read_lexicon'''
	
	file_dict = os.path.join(fs['data'], 'synonymy', name + '.pickle')
	
	if not quiet:
		print 'Reading ' + file_dict

	f = open(file_dict, 'r')
	
	# store the defs
	
	global full_def
	
	full_def = pickle.load(f)
	
	f.close()
	
	return(full_def)	


def export_dict(defs, name, quiet):
	'''export definitions as a text file'''
	
	dir_export = os.path.join(fs['data'], 'synonymy', 'dict-diagnostic')
	shutil.rmtree(dir_export)
	os.mkdir(dir_export)

	if not quiet:
		print 'Exporting plain-text definitions to {0}'.format(dir_export)
	
	keychar = None
	f = None
	
	pr = progressbar.ProgressBar(len(defs), quiet)
	
	for head in defs:
				
		if head[0] != keychar:
			keychar = head[0]
			
			file_export = os.path.join(dir_export, keychar)
			
			f = open(file_export, 'a')
		
		f.write('{0}::{1}\n'.format(head.encode('utf8'), defs[head].encode('utf8')))
		
		pr.advance()	
		
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
	# load the definitions
	#

	full_defs = read_dict('full_defs', opt.quiet)
	
	export_dict(full_defs, 'full_defs', opt.quiet)

if __name__ == '__main__':
    main()
