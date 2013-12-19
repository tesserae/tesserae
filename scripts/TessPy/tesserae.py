'''common python code for tesserae'''

def read_config(config):
	'''read the config file in dir "lib"'''
		
	fs  = dict()
	url = dict()
	lib = list()
	section = None
	
	f = open(config, 'r')
	
	for line in f:
	
		# remove comments
	
		if '#' in line:
			line = line[:line.find('#')]
			line = line.strip()
		
		# don't process lines that have no non-space chars
		
		if re.match('\S', line) is None:
			continue
		
		# check for section head
		
		m = re.match('\[(.+)\]', line)
		
		if (m is not None):
			
			section = m.group(1)
	
		# check for 'key = value' entries
	
		elif '=' in line:
	
			k, v = line.split('=')
		
			k = k.strip()
			v = v.strip()

			if (section == 'path_fs'):	
				fs[k] = v
				
			elif (section == 'path_url'):
				url[k] = v
		
		# check for plain 'value' entries
				
		elif (section == 'py_lib'):
			lib.append(line.strip())

	return(fs, url, lib)

import os
import os.path
import sys
import re

fs, url, lib = read_config(os.path.join(os.path.dirname(__file__), '..', 'tesserae.conf'))

for l in lib:
	sys.path.append(l)
