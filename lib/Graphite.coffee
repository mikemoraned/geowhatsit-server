dgram  = require('dgram')

class NoOpGraphite
  send: (name, value) ->

class Graphite
  constructor: (@apikey) ->
    @client = dgram.createSocket("udp4")

  send: (name, value) =>
    message = new Buffer(@apikey + ".#{name} #{value}\n")
    @client.send(message, 0, message.length, 2003, "carbon.hostedgraphite.com", (err, bytes) ->
      @client.close()
    )

  @initializeInHeroku: () ->
    apikey = process.env.HOSTEDGRAPHITE_APIKEY
    if apikey?
      new Graphite(apikey)
    else
      new NoOpGraphite()

module.exports = Graphite
