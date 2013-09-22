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
	# check for options
	#
	
	parser = argparse.ArgumentParser(
			description='Do something')
	parser.add_argument('-q', '--quiet', action='store_const', const=1,
			help = "Don't print status messages")
	
	opt = parser.parse_args()


if __name__ == '__main__':
    main()
