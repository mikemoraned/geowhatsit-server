dgram  = require('dgram')
net = require('net')

class LocalGraphite
  constructor: () ->
    @appName = "geowhatsit"

  send: (name, value) =>
    timestamp = (new Date().getTime() / 1000).toFixed(0)
    message = "#{@appName}.#{name} #{value} #{timestamp}"

    stream = new net.Stream()
    stream.addListener('connect', () =>
#      console.log("Connected")
#      console.log(message)
      stream.write(message)
      stream.write("\n")
      stream.end()
    )
    stream.addListener('error', (e) =>
      console.log("Dropped \"#{message}\": #{e}")
    )
    stream.connect(2003, "localhost")

class HostedGraphite
  constructor: (@apikey) ->

  send: (name, value) =>
    message = new Buffer("#{@apikey}.#{name} #{value}\n")
    client = dgram.createSocket("udp4")
    client.send(message, 0, message.length, 2003, "carbon.hostedgraphite.com", (err, bytes) ->
      client.close()
    )

class Factory
  @initializeInHeroku: () ->
    apikey = process.env.HOSTEDGRAPHITE_APIKEY
    if apikey?
      console.log("Using hosted graphite, api key: #{apikey}")
      new HostedGraphite(apikey)
    else
      console.log("Using local Graphite")
      new LocalGraphite()

module.exports = Factory
