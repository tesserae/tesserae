import pickle

# import the topic modelling tools from gensim

from gensim import corpora, models, similarities

# load the saved data from whitaker.stoplist.py

print "loading saved corpus"

fs_data = "/Volumes/CWFDATA/semantics"

f = open(fs_data + "/whitaker.corpus.pickle")
corpus = pickle.load(f)
f.close

#
# use gensim
#

# create dictionary

print "creating dictionary"

dictionary = corpora.Dictionary(corpus)
dictionary.save(fs_data + "/whitaker.dict")

# convert each sample to a bag of words

print "converting each doc to bag-of-words"

corpus = [dictionary.doc2bow(doc) for doc in corpus]

corpora.MmCorpus.serialize(fs_data + '/whitaker.mm', corpus)

#
# this bit is copied from
# 	http://radimrehurek.com/gensim/tut2.html
#

print "creating tfidf model"

tfidf = models.TfidfModel(corpus)

tfidf.save(fs_data + "/model.whitaker.tfidf")

print "transforming the corpus to tfidf"

corpus_tfidf = tfidf[corpus]

print "creating lsi model"

lsi = models.LsiModel(corpus_tfidf, id2word=dictionary, num_topics=300)

lsi.save(fs_data + "/model.whitaker.lsi")

print "transforming the corpus to lsi"

corpus_lsi = lsi[corpus_tfidf]

#
# print out the topics
#

print lsi.show_topics()
