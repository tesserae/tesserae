x <- read.table("results.corpus.stem.di-freq.txt")
colnames(x) <- c("stop", "dist", "ret", "t1", "t2", "t3", "t4", "t5", "com")

# ratio of good : bad results 

palette(rainbow(6))

png(file="good-bad.png", width=700, height=600)

par(mar=c(5,4,4,6)+.1, xpd=TRUE)
with(x, plot(stop, (t4+t5)/(t1+t2), col=dist/5, main="effects of stoplist size, max span\non ratio of good:bad results", xlab="stoplist size (words)", ylab="types 4+5 : types 1+2"))
legend("topright", legend=c(1:6)*5, title="max span", col=c(1:6), bg="white", inset=c(-.12,.10), pch=1)

dev.off()

# number of results overall

png(file="num-results.png", width=600, height=600)

options(scipen=10)

with(x, plot(stop, ret, col=dist/5, log="y", yaxt="n", main="effects of stoplist size, max span\non ratio of number of results", xlab="stoplist size (words)", ylab="number of results"))

y1 <- floor(log10(range(x$ret)))
pow <- seq(y1[1], y1[2]+1)
ticksat <- as.vector(sapply(pow, function(p) (1:10)*10^p))
axis(2, 10^pow)
axis(2, ticksat, labels=NA, tcl=-0.25, lwd=0, lwd.ticks=1)

legend("topright", legend=rev(c(1:10)*5), title="max span", col=rev(c(1:10)), pch=1, bg="white")

dev.off()


###

with(x, plot(stop, ret, col=dist/5, main="effects of stoplist size, max span\non ratio of number of results", xlab="stoplist size (words)", ylab="number of results"))
