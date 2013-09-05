url = require("url")
urlencode = require("urlencode")

LatLon = require("./LatLon")
Stream = require("./Stream")
PhraseSignature = require("./PhraseSignature")

class EvaluateFromStream extends Stream
  constructor: (@baseURL, twitter, restartAfterSeconds) ->
    super(twitter, restartAfterSeconds)

  handleData: (data) =>
    if data.geo? and data.geo.coordinates?
      latLon = new LatLon(data.geo.coordinates[0], data.geo.coordinates[1])
      sig = PhraseSignature.fromPhrase(data.text,2)
      try
        locationURL = url.resolve(@baseURL, "/locations/#{latLon.latitude},#{latLon.longitude}")
        phraseURL = url.resolve(@baseURL, "/phrases/#{urlencode(sig.toSignature())}")
        console.log("location: #{locationURL}, phrase: #{phraseURL}")
      catch e
        console.dir(e)
        console.dir("ignoring tweet: https://twitter.com/#{data.user.screen_name}/status/#{data.id_str}, text: \"" + data.text + "\"")

module.exports = EvaluateFromStream
