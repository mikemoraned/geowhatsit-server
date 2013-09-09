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
#                tf = entry.tweets
#                idf = Math.log( totalRegionCount / regionCountForNGram[entry.ngram] )
#                entry = {
#                  ngram: entry.ngram
#                  tf: tf
#                  idf: idf
#                  tf_idf: tf * idf
#                }
                ngramsWithCountAndTFIDF.push(@tfidf(entry.ngram, entry.tweets, regionCountForNGram[entry.ngram], totalRegionCount))
              callback(_.chain(ngramsWithCountAndTFIDF).sortBy((d) -> -1 * d.tf_idf).value())
          )
      )
    )

  scoredRegionsForNGrams: (ngrams, callback) ->
    @tweetCounts.countRegions((totalRegionCount) =>
      @tweetCounts.tweetCountsByRegionForNGrams(ngrams, (results) =>
        byRegion = {}
        for result in results
          ngram = result.ngram
          regionCountForNGram = result.regions.length
          for entry in result.regions
            if !byRegion[entry.region]?
              byRegion[entry.region] = []
            byRegion[entry.region].push(@tfidf(ngram, entry.tweets, regionCountForNGram, totalRegionCount))
        callback(for region, tfidfs of byRegion
          {
            region: region
            scores: tfidfs
          }
        )
      )
    )


  tfidf: (ngram, tweetsForNGram, regionCountForNGram, totalRegionCount) =>
    idf = Math.log( totalRegionCount / regionCountForNGram )
    tf = tweetsForNGram
    {
      ngram: ngram
      tweets: tweetsForNGram
      tf: tf
      idf: idf
      tf_idf: tf * idf
    }


#    callback({
#        region: 'qq'
#        scores: for ngram in ngrams
#          {
#            ngram: ngram
#            tf_idf: 1
#          }
#      })

module.exports = TFIDF