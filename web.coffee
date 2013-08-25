express = require("express")
app = express()
app.use(express.logger())

util = require('util')
twitter = require('twitter')

twit = new twitter({
  consumer_key: 'mCp0qZ0zGGcvA9ZKVo7xQ',
  consumer_secret: 'X1Z4FaK8Hv68ZoTUCmiRjDy6IP5d5n7OHYwC6es4A',
  access_token_key: '11510772-MZIWUADlvY7A9Cbz6kKpqbuRM7EfWrdskAnXNpxpE',
  access_token_secret: process.env['TWITTER_ACCESS_TOKEN_SECRET']
})

#geolib = require('geolib')

class LatLon
  constructor: (lat, lon) ->
    @latitude = lat
    @longitude = lon

  toId: () ->
    "#{@latitude},#{@longitude}"

  @fromId: (id) ->
    [latS, lonS] = id.split(",")
    new LatLon(parseFloat(latS), parseFloat(lonS))

class InMemoryTweetCounts
  constructor: () ->
    @total = 0
    @map = {}

  add: (latLon) ->
    @total++
    id = latLon.toId()
    count = @map[id]
    if count?
      @map[id] = count + 1
    else
      @map[id] = 1

  dump: (callback) ->
    callback({
      'total' : @total
      'counts' : { lat_lon: LatLon.fromId(id), count: count } for id, count of @map
    })

class RedisTweetCounts
  constructor: (@redis) ->
    @prefix = "latLon."

  add: (latLon) ->
    @incKey("total")
    @incKey(@latLonFullId(latLon))

  latLonFullId: (latLon) ->
    "#{@prefix}#{latLon.toId()}"

  incKey: (key) =>
    @redis.incr(key)

  dump: (callback) ->
    @redis.get("total", (err, totalBuffer) =>
      total = parseInt(totalBuffer.toString())
      @redis.keys("#{@prefix}*", (err, fullIds) =>
        counts = []
        for fullId in fullIds
          do (fullId) =>
            @redis.get(fullId, (err, countBuffer) =>
              id = fullId.toString().substring(@prefix.length)
              count = parseInt(countBuffer.toString())
              entry = { lat_lon: LatLon.fromId(id), count: count }
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
    try
      console.log("Using Redis")
      redis = require("heroku-redis-client").createClient()

      new RedisTweetCounts(redis)
    catch e
      console.log("Falling back to in-memory counts")
      console.dir(e)
      new InMemoryTweetCounts()

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

geohash = require('ngeohash')
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