express = require("express")
app = express()
app.use(express.logger())

_ = require('underscore')
geohash = require('ngeohash')

LatLon = require("./lib/LatLon")
TweetCountsFactory = require("./lib/TweetCountsFactory")
TweetTokenizer = require("./lib/TweetTokenizer")
Stream = require("./lib/Stream")
Graphite = require("./lib/Graphite")
MetricCollector = require("./lib/MetricCollector")
TwitterAccess = require('./lib/TwitterAccess')

tweetCounts = TweetCountsFactory.create(2)

collector = new MetricCollector(Graphite.initializeInHeroku(), [tweetCounts])
collector.collect()
collector.beginPolling(60 * 1000)

stream = new Stream(tweetCounts, TwitterAccess.init(), new TweetTokenizer(2))
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