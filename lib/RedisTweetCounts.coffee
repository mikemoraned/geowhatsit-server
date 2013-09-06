_ = require('underscore')
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
    @tweetCountsPerRegion((results) =>
      withSummaries = for result in results
        {
          region: result.region,
          summary: {
            tweets: result.tweets
          }
        }
      callback(withSummaries)
    )

  summariseRegion: (geoHash, callback) =>
    @summariseRegions((results) =>
      filtered = _.chain(results).filter((d) -> d.region.hash == geoHash).value()
      if filtered.length == 1
        callback(filtered[0])
      else
        callback(null)
    )

  tweetCountsPerRegion: (callback) =>
    @redis.zrevrange(["#{@version}.geohashes:#{@precision}", 0, -1, 'withscores'], (err, response) =>
      results = []
      for keyIndex in [0 ... response.length] by 2
        fullId = response[keyIndex]
        geoHash = fullId.toString().substring(@prefix.length)
        count = parseInt(response[keyIndex + 1].toString())
        result = { region: GeoHashRegion.fromHash(geoHash), tweets: count }
        results.push(result)
      callback(results)
    )

  ngramCountsForRegion: (geoHash, callback) =>
    @redis.hgetall("#{@prefix}#{geoHash}", (err, response) =>
      results = []
      for fullNGramId, value of response
        ngram = fullNGramId.toString().substring("#{@version}.ngram:2:".length)
        count = parseInt(value.toString())
        result = { ngram: ngram, tweets: count }
        results.push(result)
      callback(_.sortBy(results, (d) -> -1 * d.tweets))
    )

  countRegionsInWhichNGramOccurs: (nGram, callback) =>
    @redis.hlen("#{@version}.ngram:#{nGram.length}:#{nGram}", (err, result) =>
#      console.dir(result)
      callback({ ngram: nGram, regions: parseInt(result) })
    )

  countRegions: (callback) =>
    @redis.zcard("#{@version}.geohashes:#{@precision}", (err, result) =>
      callback(parseInt(result))
    )

  overallNGramCounts: (callback) =>
    @redis.zrevrange(["#{@version}.ngrams:2", 0, -1, 'withscores'], (err, response) =>
      results = []
      for keyIndex in [0 ... response.length] by 2
        fullId = response[keyIndex]
        ngram = fullId.toString().substring("#{@version}.ngram:".length)
        count = parseInt(response[keyIndex + 1].toString())
        result = { ngram: ngram, tweets: count }
        results.push(result)
      callback(results)
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
