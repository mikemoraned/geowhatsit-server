express = require("express")
app = express()
app.use(express.logger())

twitter = require('twitter')
_ = require('underscore')

LatLon = require("./LatLon.js")
TweetCountsFactory = require("./TweetCountsFactory.js")
TweetTokenizer = require("./TweetTokenizer.js")
Stream = require("./Stream.js")

twit = new twitter({
  consumer_key: 'mCp0qZ0zGGcvA9ZKVo7xQ',
  consumer_secret: 'X1Z4FaK8Hv68ZoTUCmiRjDy6IP5d5n7OHYwC6es4A',
  access_token_key: '11510772-MZIWUADlvY7A9Cbz6kKpqbuRM7EfWrdskAnXNpxpE',
  access_token_secret: process.env['TWITTER_ACCESS_TOKEN_SECRET']
})

tweetCounts = TweetCountsFactory.create()
stream = new Stream(tweetCounts, twit, new TweetTokenizer(2))
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