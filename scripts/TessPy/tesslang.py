# -*- coding: utf-8

import re

def beta_to_uni(beta):
	code = [		
		(r'\)',unichr(0x0313)),
		(r'\(',unichr(0x0314)),
		(r'\/',unichr(0x0301)),
		(r'\=',unichr(0x0342)),
		(r'\\',unichr(0x0300)),
		(r'\+',unichr(0x0308)),
		(r'\|',unichr(0x0345)),
	
		(r'\*a',u'Α'),	(r'a',u'α'),
		(r'\*b',u'Β'),	(r'b',u'β'),
		(r'\*g',u'Γ'),	(r'g',u'γ'),
		(r'\*d',u'Δ'),	(r'd',u'δ'),
		(r'\*e',u'Ε'),	(r'e',u'ε'),
		(r'\*z',u'Ζ'),	(r'z',u'ζ'),
		(r'\*h',u'Η'),	(r'h',u'η'),
		(r'\*q',u'Θ'),	(r'q',u'θ'),
		(r'\*i',u'Ι'),	(r'i',u'ι'),
		(r'\*k',u'Κ'),	(r'k',u'κ'),
		(r'\*l',u'Λ'),	(r'l',u'λ'),
		(r'\*m',u'Μ'),	(r'm',u'μ'),
		(r'\*n',u'Ν'),	(r'n',u'ν'),
		(r'\*c',u'Ξ'),	(r'c',u'ξ'),
		(r'\*o',u'Ο'),	(r'o',u'ο'),
		(r'\*p',u'Π'),	(r'p',u'π'),
		(r'\*r',u'Ρ'),	(r'r',u'ρ'),
						(r's\b',u'ς'),
		(r'\*s',u'Σ'),	(r's',u'σ'),
		(r'\*t',u'Τ'),	(r't',u'τ'),
		(r'\*u',u'Υ'),	(r'u',u'υ'),
		(r'\*f',u'Φ'),	(r'f',u'φ'),
		(r'\*x',u'Χ'),	(r'x',u'χ'),
		(r'\*y',u'Ψ'),	(r'y',u'ψ'),
		(r'\*w',u'Ω'),	(r'w',u'ω')
	]
	
	caps_adj = re.compile(r'(\*)([^a-z ]+)')
	
	beta = caps_adj.sub(r'\2\1', beta)
	
	for t in code:
		pat, sub = t
		
		pat = re.compile(pat, re.U)
		
		beta = pat.sub(sub, beta)
	
	return beta

