_ = require('underscore')

class TFIDF
  constructor: (@tweetCounts) ->

  ngramsForRegionOrderedByScore: (region, callback) ->
    @tweetCounts.countRegions((totalRegionCount) =>
      @tweetCounts.ngramCountsForRegion(region, (forRegion) =>
        numNGrams = forRegion.length
        returned = 0
        regionCountForNGram = {}
        for entry in forRegion
          @tweetCounts.countRegionsInWhichNGramOccurs(entry.ngram, (result) =>
            returned += 1
            regionCountForNGram[result.ngram] = result.regions
            if returned == numNGrams
              ngramsWithCountAndTFIDF = []
              for entry in forRegion
                tf = entry.tweets
                idf = Math.log( totalRegionCount / regionCountForNGram[entry.ngram] )
                entry = {
                  ngram: entry.ngram
                  tweets: entry.tweets
                  tf: tf
                  idf: idf
                  tf_idf: tf * idf
                }
                ngramsWithCountAndTFIDF.push(entry)
              callback(_.chain(ngramsWithCountAndTFIDF).sortBy((d) -> -1 * d.tf_idf).value())
          )
      )
    )

module.exports = TFIDF