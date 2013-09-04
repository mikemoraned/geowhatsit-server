express = require("express")
app = express()
app.use(express.logger())

_ = require('underscore')
geohash = require('ngeohash')

LatLon = require("./lib/LatLon")
TweetCountsFactory = require("./lib/TweetCountsFactory")
SurprisingNGrams = require("./lib/SurprisingNGrams")
TFIDF = require("./lib/TFIDF")

tweetCounts = TweetCountsFactory.create(2)
surprising = new SurprisingNGrams(tweetCounts)
tfidf = new TFIDF(tweetCounts)

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

app.get('/regions', (req, resp) ->
  tweetCounts.summariseRegions((results) ->
    expanded = for result in results
      region = result.region
      {
        name: region.hash
        geo: {
          center: region.center
          bbox: region.boundingBox()
        }
        summary: result.summary,
        ngrams: {
          href: "/regions/#{region.hash}/ngrams"
        }
      }
    resp.send(expanded)
  )
)

app.get('/regions/:geohash/ngrams', (req, resp) ->
  tweetCounts.ngramCountsForRegion(req.params.geohash, (results) ->
    resp.send(results)
  )
)

app.get('/regions/:geohash/ngrams/surprising', (req, resp) ->
  surprising.surprisingNGramsForRegion(req.params.geohash, (results) ->
    resp.send(results)
  )
)

app.get('/regions/:geohash/ngrams/tfidf', (req, resp) ->
  tfidf.ngramsForRegionOrderedByScore(req.params.geohash, (results) ->
    resp.send(results)
  )
)

app.get('/regions/:geohash/ngrams/tfidf', (req, resp) ->
  surprising.surprisingNGramsForRegion(req.params.geohash, (results) ->
    resp.send(results)
  )
)

app.get('/ngrams', (req, resp) ->
  tweetCounts.overallNGramCounts((results) ->
    resp.send(results)
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