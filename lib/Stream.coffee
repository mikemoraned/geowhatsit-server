class Stream
  constructor: (@twitter, restartAfterSeconds = 30 * 60) ->
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

module.exports = Stream
