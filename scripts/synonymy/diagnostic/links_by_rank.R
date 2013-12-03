#
# read data
#

print('reading data')

fr.g <- read.table('grc.freq_distr')
fr.l <- read.table('la.freq_distr')
links <- read.table('links_by_rank')

#
# define plot
#

print('defining plot')

plot.new()
plot.window(xlim=c(1,max(nrow(fr.l),nrow(fr.g))), ylim=c(0,1))

#
# plot links
#

print('plotting links')

palette(rainbow(6))

for (i in 1:nrow(links)) {

	g <- links[i,1]
	l <- links[i,2]
	
	diff <- round(abs(log(g)-log(l)))
	lines(x=c(g,l), y=c(0,1), col=diff, lw=.2)
}
	
