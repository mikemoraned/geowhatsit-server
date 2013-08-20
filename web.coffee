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

geolib = require('geolib')

class LatLon
  constructor: (lat, lon) ->
    @latitude = lat
    @longitude = lon

  canonicalId: () ->
    "#{@latitude},#{@longitude}"

class TweetCounts
  constructor: () ->
    @total = 0
    @map = {}

  add: (latLon) ->
    @total++
    id = latLon.canonicalId()
    count = @map[id]
    if count?
      @map[id] = count + 1
    else
      @map[id] = 1

  dump: () -> {
    'total' : @total
    'lat_lon' : @map
  }

tweetCounts = new TweetCounts

twit.stream('statuses/sample', (stream) ->
  stream.on('data', (data) ->
    if data.geo? and data.geo.coordinates?
#      console.log(util.inspect(data))
      tweetCounts.add(new LatLon(data.geo.coordinates[0], data.geo.coordinates[1]))
  )
)

app.get('/', (request, response) ->
  response.send('Hello World!')
)
app.get('/counts.json', (request, response) ->
  response.send(tweetCounts.dump())
)


port = process.env.PORT || 5000
app.listen(port, () ->
  console.log("Listening on " + port)
)