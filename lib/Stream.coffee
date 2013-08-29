LatLon = require("./LatLon.js")

class Stream
  constructor: (@tweetCounts, @twitter, @tokenizer, restartAfterSeconds = 30 * 60) ->
    @restartAfterMillis = restartAfterSeconds * 1000

  start: () ->
    @twitter.stream('statuses/sample', (stream) =>
      @stream = stream
      console.log("Started listening for tweets, will restart after #{@restartAfterMillis} millis")
      stream.on('data', @handleData)
      setTimeout(@restart, @restartAfterMillis)
    )

  restart: () =>
    if @stream?
      console.log("Destroying stream")
      @stream.destroy()
    @start()

  handleData: (data) =>
    if data.geo? and data.geo.coordinates?
      @tweetCounts.add(new LatLon(data.geo.coordinates[0], data.geo.coordinates[1]), @tokenizer.nGrams(data.text))

module.exports = Stream
