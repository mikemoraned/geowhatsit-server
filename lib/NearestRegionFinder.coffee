_ = require('underscore')
ByMostTweets = require("./finders/ByMostTweets")
BySumOfTFIDFScore = require("./finders/BySumOfTFIDFScore")

class NearestRegionFinder
  constructor: (@tweetCounts) ->
    @finders = [{
      name: 'by_most_tweets',
      finder: new ByMostTweets(@tweetCounts)
    },
    {
      name: 'by_sum_of_tfidf_score',
      finder: new BySumOfTFIDFScore(@tweetCounts)
    }]

  nearest: (signature, limit, callback) ->
    nearest = {}
    found = 0
    for entry in @finders
      do (entry) =>
        entry.finder.nearest(signature, limit, (results) =>
          found += 1
          nearest[entry.name] = results
          if found == @finders.length
            callback(nearest)
        )

module.exports = NearestRegionFinder