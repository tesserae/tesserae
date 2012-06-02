fs_data = "/Volumes/CWFDATA/semantics"

mydata <- as.matrix(read.table(paste(fs_data, "/whitaker.lsi-table.txt", sep=""), row.names=1))

synclass <- kmeans(mydata, 300)

write.table(synclass$cluster, file=paste(fs_data, "/whitaker.classes.txt", sep=""))