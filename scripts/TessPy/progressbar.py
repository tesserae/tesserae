import sys

#
# a progress bar
#

class ProgressBar:
	def __init__(self, value, quiet=0):
		self._total = value
		self._quiet = quiet 
		self._prev = 0
		self._current = 0
		self.done = 0
		self._prec = 0.00001
	
	def advance(self, step=1):
		self._current = self._current + step
		
		if self._current >= self._prev + self._prec:
			
			self.prprint()
			self._prev = self._prev + self._prec

		if self._current >= self._total:
			
			self.prprint()
			self._prev = self._total
			self._current = self._total
			self.done = 1
			self.finish()
	
	def prprint(self):
		if not self._quiet:
			print '\r{0:3.1f}% done'.format(100 * self._current / self._total),
			sys.stdout.flush()
		
	def finish(self):
		if not self._quiet:
			print

