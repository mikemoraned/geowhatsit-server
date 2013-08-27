express = require("express")
app = express()
app.use(express.logger())

util = require('util')
twitter = require('twitter')
geohash = require('ngeohash')

twit = new twitter({
  consumer_key: 'mCp0qZ0zGGcvA9ZKVo7xQ',
  consumer_secret: 'X1Z4FaK8Hv68ZoTUCmiRjDy6IP5d5n7OHYwC6es4A',
  access_token_key: '11510772-MZIWUADlvY7A9Cbz6kKpqbuRM7EfWrdskAnXNpxpE',
  access_token_secret: process.env['TWITTER_ACCESS_TOKEN_SECRET']
})

class LatLon
  constructor: (lat, lon) ->
    @latitude = lat
    @longitude = lon

  toId: () ->
    "#{@latitude},#{@longitude}"

  toGeoHash: (precision) ->
    geohash.encode(@latitude, @longitude, precision)

  @fromId: (id) ->
    [latS, lonS] = id.split(",")
    new LatLon(parseFloat(latS), parseFloat(lonS))

  @fromGeoHash: (geoHash) ->
    decoded = geohash.decode(geoHash)
    new LatLon(decoded.latitude, decoded.longitude)

class RedisTweetCounts
  constructor: (@redis, @precision = 6) ->
    @version = "v2"
    @prefix = "#{@version}.geohash:#{@precision}:"

  add: (latLon) ->
    @incKey("#{@version}count")
    @incKey(@latLonFullId(latLon))

  latLonFullId: (latLon) =>
    "#{@prefix}#{latLon.toGeoHash(@precision)}"

  incKey: (key) =>
    @redis.incr(key)

  dump: (callback) ->
    @redis.get("#{@version}count", (err, totalBuffer) =>
      total = parseInt(totalBuffer.toString())
      @redis.keys("#{@prefix}*", (err, fullIds) =>
        counts = []
        for fullId in fullIds
          do (fullId) =>
            @redis.get(fullId, (err, countBuffer) =>
              geoHash = fullId.toString().substring(@prefix.length)
              count = parseInt(countBuffer.toString())
              entry = { lat_lon: LatLon.fromGeoHash(geoHash), count: count }
              counts.push(entry)
              if fullIds.length == counts.length
                callback({
                  'total'  : total,
                  'counts' : counts
                })
            )
      )
    )

class TweetCountsFactory
  @create: () ->
    redis = require('redis')
    if process.env.REDISCLOUD_URL?
      console.log("Using RedisCloud Redis")
      url = require('url')
      redisURL = url.parse(process.env.REDISCLOUD_URL)
      client = redis.createClient(redisURL.port, redisURL.hostname, {no_ready_check: true})
      client.auth(redisURL.auth.split(":")[1])
    else
      console.log("Using Local Redis")
      client = redis.createClient()

    new RedisTweetCounts(client)

class Stream
  constructor: (@tweetCounts, @twitter, restartAfterSeconds = 30 * 60) ->
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
      @tweetCounts.add(new LatLon(data.geo.coordinates[0], data.geo.coordinates[1]))

tweetCounts = TweetCountsFactory.create()
stream = new Stream(tweetCounts, twit)
stream.start()

app.all('*', (req, resp, next) ->
  resp.header("Access-Control-Allow-Origin", "*")
  resp.header("Access-Control-Allow-Headers", "X-Requested-With")
  next()
)

app.get('/', (req, resp) ->
  resp.send('Hello World!')
)
app.get('/counts.json', (req, resp) ->
  tweetCounts.dump((dumped) ->
    resp.send(dumped)
  )
)

_ = require('underscore')
app.get('/counts/grouped-by-geohash/precision-:precision.json', (req, resp) ->
  tweetCounts.dump((dumped) ->
    byGeoHash = _.countBy(dumped.counts, (entry) ->
      geohash.encode(entry.lat_lon.latitude, entry.lat_lon.longitude, req.params.precision)
    )
    counts = _.map(byGeoHash, (count, encoded) ->
      {
      'lat_lon' : geohash.decode(encoded),
      'count'   : count
      })
    resp.send({ 'total' : dumped.total, 'counts': counts })
  )
)


port = process.env.PORT || 5000
app.listen(port, () ->
  console.log("Listening on " + port)
)