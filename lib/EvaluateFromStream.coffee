url = require("url")
urlencode = require("urlencode")
request = require("request")

LatLon = require("./LatLon")
Stream = require("./Stream")
PhraseSignature = require("./PhraseSignature")

class EvaluateFromStream extends Stream
  constructor: (@baseURL, twitter, restartAfterSeconds) ->
    super(twitter, restartAfterSeconds)
    @regionCounts = {}
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
            try
              expectedRegion = JSON.parse(body).region
              @incRegionCounts(expectedRegion.name)
              request(phraseURL, (error, response, body) =>
                if !error && response.statusCode == 200
                  try
                    nearest = JSON.parse(body).nearest
                    if nearest?
                      @incStat("evaluated")
                      some_correct = false
                      for algorithm, results of nearest
                        top = results[0]
                        correct = expectedRegion.name == top.name
                        some_correct = correct || some_correct
                        console.log("#{expectedRegion.name},#{top.name},#{correct}")
                        if correct
                          @incStat("algorithm.#{algorithm}.correct")
                      if some_correct
                        @incStat("correct")
                  catch e
                    @ignoreTweetOnError(e, data)
              )
            catch e
              @ignoreTweetOnError(e, data)
        )
      catch e
        @ignoreTweetOnError(e, data)

  ignoreTweetOnError: (e, data) =>
    console.dir(e)
    console.dir("ignoring tweet: https://twitter.com/#{data.user.screen_name}/status/#{data.id_str}, text: \"" + data.text + "\"")

  incStat: (name) =>
    if @stats[name]?
      @stats[name] = @stats[name] + 1
    else
      @stats[name] = 1

  incRegionCounts: (name) =>
    if @regionCounts[name]?
      @regionCounts[name] = @regionCounts[name] + 1
    else
      @regionCounts[name] = 1

  dumpStats: () =>
    console.dir(@stats)
#    console.dir(@regionCounts)

  collectMetrics: (collector) =>
    @dumpStats()
    for key, value of @stats
      collector.send("evaluate.#{key}", value)
#    for key, value of @regionCounts
#      collector.send("evaluate.region.has_geo.#{key}", value)

module.exports = EvaluateFromStream
