_ = require('underscore')
TFIDF = require("../TFIDF")
GeoHashRegion = require("../GeoHashRegion")
PhraseSignature = require("../PhraseSignature")

class BySumOfTFIDFScore
  constructor: (@tweetCounts) ->
    @tfidf = new TFIDF(@tweetCounts)

  nearest: (signature, limit, callback) ->
    ngrams = signature.toNGrams()
    @tfidf.scoredRegionsForNGrams(ngrams, (scored) =>
      summed = for entry in scored
        {
          region: entry.region
          score: score = _.chain(entry.scores).pluck("tf_idf").reduce((m, d) -> m + d).value()
        }
      callback(_.chain(summed)
        .sortBy((d) -> d.score)
        .first(limit)
        .pluck("region")
        .filter((d) -> d != "[object Object]") # remove some guff (a hack)
        .map((d) -> GeoHashRegion.fromHash(d)).value())
    )

module.exports = BySumOfTFIDFScore