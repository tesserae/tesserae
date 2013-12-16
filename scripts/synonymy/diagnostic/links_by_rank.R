#
# read data
#

print('reading data')

fr.g <- read.table('grc.freq_distr')
fr.l <- read.table('la.freq_distr')
links <- read.table('links_by_rank')

#
# plot zipfian curves
#

png(file='fr.l.png', width=600, height=200)

plot.new()
plot.window(xlim=c(1,max(nrow(fr.l),nrow(fr.g))), ylim=c(.0000001,max(fr.l[,2], fr.g[,2])))

title(main='Latin', xlab='Rank Position', ylab='Frequency')
axis(side=1)
axis(side=2)

lines(fr.l[,2], lw=2, col=rgb(.2, .2, .4))

dev.off()

png(file='fr.g.png', width=600, height=200)

plot.new()
plot.window(xlim=c(1,max(nrow(fr.l),nrow(fr.g))), ylim=c(.0000001,max(fr.l[,2], fr.g[,2])))

title(main='Greek', xlab='Rank Position', ylab='Frequency')
axis(side=1)
axis(side=2)

lines(fr.l[,2], lw=2, col=rgb(.2, .2, .4))

dev.off()


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
	
