# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# define the data directory

path_data = "/Volumes/CWFDATA/semantics"

# load the data from whitaker.models.py

print "loading saved dictionary"

dictionary = corpora.Dictionary.load(path_data + "/whitaker.dict")

print "loading saved corpus"

corpus = corpora.MmCorpus(path_data + "/whitaker.mm")

print "loading saved tfidf model"

tfidf = models.TfidfModel.load(path_data + "/model.whitaker.tfidf")

print "creating tfidf wrapper for corpus"

corpus_tfidf = tfidf[corpus]

print "loading saved lsi model"

lsi = models.LsiModel.load(path_data + "/model.whitaker.lsi")

print "creating lsi wrapper for corpus"

corpus_lsi = lsi[corpus_tfidf]

#
# calculate similarities
#

print "calculating similarities"

index = similarities.MatrixSimilarity(corpus_lsi)

print "saving index"

index.save(path_data + "/whitaker.lsi.index")

