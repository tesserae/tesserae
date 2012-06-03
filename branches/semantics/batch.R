heads = c(50, 100, 200)
sims  = c(50, 70, 90)

for (h in 1:3) {
	
	for (s in 1:3) {
		
		hdata <- read.table(paste("batch/h", heads[h], "s", sims[s], ".hist", sep=""), header=TRUE)
		
		x11(title=paste("heads=", heads[h], "; sim=", sims[s], sep=""))
		
		plot(hdata, main=paste("heads=", heads[h], "\nsim=", sims[s], sep=""), xlab="number of words", ylab="number of synonyms")
				
	}
}

for (h in heads) {
	
	s5 <- read.table(paste("batch/h", h, "s50.hist", sep=""), header=TRUE)
	s7 <- read.table(paste("batch/h", h, "s70.hist", sep=""), header=TRUE)
	s9 <- read.table(paste("batch/h", h, "s90.hist", sep=""), header=TRUE)
	
	x11(title=paste("heads=", h, sep=""))
	
	xmax = log(max(s5$syns, s7$syns, s9$syns))
	ymax = log(max(s5$words, s7$words, s9$words))
	
	plot(log(s5$syns), log(s5$words), main=paste("heads=", h, sep=""), xlab="no. of synonyms", ylab="log no. of words", type="n", xlim=c(0,xmax), ylim=c(0,ymax))
	
	lines(log(s5$syns), log(s5$words), lw=2, lt=1, col=1)
	lines(log(s7$syns), log(s7$words), lw=2, lt=2, col=2)
	lines(log(s9$syns), log(s9$words), lw=2, lt=3, col=3)
	
	legend("topright", c(".5", ".7", ".9"), title="min similarity", col=c(1,2,3), lt=c(1,2,3), lw=2)
}
