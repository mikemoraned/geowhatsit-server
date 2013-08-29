LatLon = require("./LatLon")

class RedisTweetCounts
  constructor: (@redis, @precision) ->
    @version = "v3"
    @prefix = "#{@version}.geohash:#{@precision}:"

  add: (latLon, text) ->
    @redis.incr("#{@version}.#{@precision}:count")
    latLonId = @latLonFullId(latLon)
    @redis.zincrby("#{@version}.geohashes:#{@precision}", 1, latLonId)
    for nGram in text.nGrams
      nGramId = "#{@version}.ngram:#{text.length}:#{nGram}"
      @redis.zincrby("#{@version}.ngrams:#{text.length}", 1, nGramId)
      @redis.hincrby(latLonId, nGramId, 1)
      @redis.hincrby(nGramId, latLonId, 1)

  latLonFullId: (latLon) =>
    "#{@prefix}#{latLon.toGeoHash(@precision)}"

  dump: (callback) ->
    @redis.get("#{@version}.#{@precision}:count", (err, totalBuffer) =>
      if err?
        console.log(err)
        callback({
          'total'  : 0,
          'counts' : 0
        })
      else
        total = parseInt(totalBuffer.toString())
        @redis.zrange(["#{@version}.geohashes:#{@precision}", 0, -1, 'withscores'], (err, response) =>
#          console.dir(response)
          counts = []
          for keyIndex in [0 ... response.length] by 2
            fullId = response[keyIndex]
            geoHash = fullId.toString().substring(@prefix.length)
            count = parseInt(response[keyIndex + 1].toString())
            entry = { lat_lon: LatLon.fromGeoHash(geoHash), count: count }
            counts.push(entry)
          callback({
            'total'  : total,
            'counts' : counts
          })
        )
    )

module.exports = RedisTweetCounts
