_ = require('underscore')

class SurprisingNGrams
  constructor: (@tweetCounts) ->

  surprisingNGramsForRegion: (region, callback) ->
    @tweetCounts.overallNGramCounts((overall) =>
      @tweetCounts.ngramCountsForRegion(region, (forRegion) =>
        overallSum = @sumNGrams(overall)
        overallMap = @toMap(overall)
        forRegionSum = @sumNGrams(forRegion)
        forRegionMap = @toMap(forRegion)

#        console.dir(overallSum)
#        console.dir(overallMap)
#        console.dir(forRegionSum)
#        console.dir(forRegionMap)

        surpriseFn = (d) =>
          overallRatio = overallMap[d.ngram] / overallSum
          forRegionRatio = forRegionMap[d.ngram] / forRegionSum
          surprise = forRegionRatio / overallRatio
          {
            ngram: d.ngram
            tweets: d.tweets
            expectedRatio: overallRatio
            actualRatio: forRegionRatio
            surprise: surprise
          }

        result = _.chain(forRegion).map(surpriseFn).sortBy((d) -> -1 * d.surprise).value()
        callback(result)
      )
    )

  sumNGrams: (d) -> _.chain(d).pluck("tweets").reduce(((m, d) -> m + d), 0).value()
  toMap: (d) ->
    _.chain(d)
      .reduce(((m, d) ->
        m[d.ngram] = d.tweets
        m
      ), {})
      .value()

module.exports = SurprisingNGrams