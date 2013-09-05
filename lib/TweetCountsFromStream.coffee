LatLon = require("./LatLon")
Stream = require("./Stream")

class TweetCountsFromStream extends Stream
  constructor: (@tweetCounts, twitter, @tokenizer, restartAfterSeconds) ->
    super(twitter, restartAfterSeconds)

  handleData: (data) =>
    if data.geo? and data.geo.coordinates?
      @tweetCounts.add(new LatLon(data.geo.coordinates[0], data.geo.coordinates[1]), @tokenizer.nGrams(data.text))

module.exports = TweetCountsFromStream
