_ = require('underscore')

class NearestRegionFinder
  constructor: (@tweetCounts) ->

  nearest: (signature, limit, callback) ->
    @tweetCounts.tweetCountsPerRegion((results) =>
      callback(
        _.chain(results)
          .sortBy((d) -> -1 * d.tweets)
          .first(limit)
          .pluck("region")
          .filter((d) -> d.hash != "[object Object]") # remove some guff (a hack)
          .value())
    )

module.exports = NearestRegionFinder