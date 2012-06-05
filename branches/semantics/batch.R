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
	
	s5 <- s5[order(s5$syns),]
	s7 <- s7[order(s7$syns),]	
	s9 <- s9[order(s9$syns),]	
	
	# quartz(title=paste("heads=", h, sep=""))
	# par(mar=c(6,4,4,4))
	
	png(file=paste("batch/h", h, ".png", sep=""))
	
	xmax = max(s5$syns, s7$syns, s9$syns)
	ymax = max(s5$words, s7$words, s9$words)
	
	plot(s5$syns, s5$words, main=paste("heads=", h, sep=""), xlab="# synonyms", ylab="# words", type="n", xlim=c(1,xmax), ylim=c(1,ymax), log="xy")
	
	lines(s5$syns, s5$words, lw=2, lt=1, col=1)
	lines(s7$syns, s7$words, lw=2, lt=2, col=2)
	lines(s9$syns, s9$words, lw=2, lt=3, col=3)
	
	legend("topright", c(".5", ".7", ".9"), title="min similarity", col=c(1,2,3), lt=c(1,2,3), lw=2)
	
	dev.off()
}

for (s in sims) {
	
	h50  <- read.table(paste("batch/h50s", s, ".hist", sep=""), header=TRUE)
	h100 <- read.table(paste("batch/h100s", s, ".hist", sep=""), header=TRUE)
	h200 <- read.table(paste("batch/h200s", s, ".hist", sep=""), header=TRUE)
	
	h50  <- h50[order(h50$syns),]
	h100 <- h100[order(h100$syns),]
	h200 <- h200[order(h200$syns),]
	
	# quartz(title=paste("similarity=", s, sep=""))
	# par(mar=c(6,4,4,4))
	
	png(file=paste("batch/s", s, ".png", sep=""))
	
	xmax = max(h50$syns,  h100$syns,  h200$syns)
	ymax = max(h50$words, h100$words, h200$words)
	
	plot(h50$syns, h50$words, main=paste("similarity=", s, sep=""), xlab="# synonyms", ylab="# words", type="l", xlim=c(1,xmax), ylim=c(1,ymax), log="xy")
	
	lines(h50$syns,  h50$words,  lw=2, lt=1, col=1)
	lines(h100$syns, h100$words, lw=2, lt=2, col=2)
	lines(h200$syns, h200$words, lw=2, lt=3, col=3)
	
	legend("topright", c("50", "100", "200"), title="max headwords", col=c(1,2,3), lt=c(1,2,3), lw=2)
	
	dev.off()
}
