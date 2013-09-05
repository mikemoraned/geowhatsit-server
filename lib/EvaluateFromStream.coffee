url = require("url")
urlencode = require("urlencode")
request = require("request")

LatLon = require("./LatLon")
Stream = require("./Stream")
PhraseSignature = require("./PhraseSignature")

class EvaluateFromStream extends Stream
  constructor: (@baseURL, twitter, restartAfterSeconds) ->
    super(twitter, restartAfterSeconds)
    @stats = {
      seen: 0
      has_geo: 0
      evaluated: 0
      correct: 0
    }

  handleData: (data) =>
    @incStat("seen")
    if data.geo? and data.geo.coordinates?
      @incStat("has_geo")
      latLon = new LatLon(data.geo.coordinates[0], data.geo.coordinates[1])
      sig = PhraseSignature.fromPhrase(data.text,2)

      try
        locationURL = url.resolve(@baseURL, "/locations/#{latLon.latitude},#{latLon.longitude}")
        phraseURL = url.resolve(@baseURL, "/phrases/#{urlencode(sig.toSignature())}")
        console.log("location: #{locationURL}, phrase: #{phraseURL}")

        request(locationURL, (error, response, body) =>
          if !error && response.statusCode == 200
            expectedRegionURL = url.resolve(locationURL, JSON.parse(body).region)
            request(phraseURL, (error, response, body) =>
              if !error && response.statusCode == 200
                @incStat("evaluated")
                nearestRegionURL = url.resolve(phraseURL, JSON.parse(body).nearest[0])
                correct = expectedRegionURL == nearestRegionURL
                console.log("#{expectedRegionURL},#{nearestRegionURL},#{correct}")
                if correct
                  @incStat("correct")
            )
        )
      catch e
        console.dir(e)
        console.dir("ignoring tweet: https://twitter.com/#{data.user.screen_name}/status/#{data.id_str}, text: \"" + data.text + "\"")

  incStat: (name) =>
    @stats[name] = @stats[name] + 1

  dumpStats: () =>
    console.dir(@stats)

  collectMetrics: (collector) =>
    @dumpStats()
    for key, value of @stats
      collector.send("evaluate.#{key}", value)

module.exports = EvaluateFromStream
