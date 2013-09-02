LatLon = require("./LatLon")
GeoHashRegion = require("./GeoHashRegion")

class RedisTweetCounts
  constructor: (@redis, @precision) ->
    @version = "v3"
    @prefix = "#{@version}.geohash:#{@precision}:"

  add: (latLon, text) ->
    @redis.incr("#{@version}.#{@precision}:count")
    fullGeoHashId = @fullGeoHashId(latLon)
    @redis.zincrby("#{@version}.geohashes:#{@precision}", 1, fullGeoHashId)
    for nGram in text.nGrams
      nGramId = "#{@version}.ngram:#{text.length}:#{nGram}"
      @redis.zincrby("#{@version}.ngrams:#{text.length}", 1, nGramId)
      @redis.hincrby(fullGeoHashId, nGramId, 1)
      @redis.hincrby(nGramId, fullGeoHashId, 1)

  collectMetrics: (collector) ->
    @redis.get("#{@version}.#{@precision}:count", (err, totalBuffer) =>
      if !err? and totalBuffer?
        total = parseInt(totalBuffer.toString())
        collector.send("tweets.total", total)
    )

  fullGeoHashId: (latLon) =>
    "#{@prefix}#{GeoHashRegion.fromPointInRegion(latLon, @precision)}"

  summariseRegions: (callback) =>
    @redis.zrange(["#{@version}.geohashes:#{@precision}", 0, -1], (err, response) =>
      geohashes = for keyIndex in [0 ... response.length]
        fullId = response[keyIndex]
        fullId.toString().substring(@prefix.length)
      withSummaries = for geohash in geohashes
        region = GeoHashRegion.fromHash(geohash)
        {
          name: geohash,
          geo: {
            center: region.center,
            bbox: region.boundingBox()
          }
        }
      callback(withSummaries)
    )

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
        @redis.zrevrange(["#{@version}.geohashes:#{@precision}", 0, -1, 'withscores'], (err, response) =>
#          console.dir(response)
          counts = []
          for keyIndex in [0 ... response.length] by 2
            fullId = response[keyIndex]
            geoHash = fullId.toString().substring(@prefix.length)
            count = parseInt(response[keyIndex + 1].toString())
            entry = { lat_lon: GeoHashRegion.fromHash(geoHash).center, count: count }
            counts.push(entry)
          callback({
            'total'  : total,
            'counts' : counts
          })
        )
    )

module.exports = RedisTweetCounts
