express = require("express")
app = express()
app.use(express.logger())
app.use(express.bodyParser())

_ = require('underscore')
geohash = require('ngeohash')

LatLon = require("./lib/LatLon")
TweetCountsFactory = require("./lib/TweetCountsFactory")
SurprisingNGrams = require("./lib/SurprisingNGrams")
TFIDF = require("./lib/TFIDF")
PhraseSignature = require("./lib/PhraseSignature")
NearestRegionFinder = require("./lib/NearestRegionFinder")

ngramLength = 2
tweetCounts = TweetCountsFactory.create(ngramLength)
surprising = new SurprisingNGrams(tweetCounts)
regionFinder = new NearestRegionFinder(tweetCounts)
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
        },
        hrefs: {
          ngrams: "/regions/#{region.hash}/ngrams",
          surprising: "/regions/#{region.hash}/ngrams/surprising"
          tfidf: "/regions/#{region.hash}/ngrams/tfidf"
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

app.get('/phrases', (req, resp) ->
  resp.send('''
            <!doctype html>
            <html lang=en>
            <meta charset=utf-8>
            <title>enter phrase</title>
            <p>enter phrase:</p>
            <form method="POST" >
              <textarea name="phrase[text]"></textarea>
              <input type="submit"/>
            </form>
            ''')
)

app.post('/phrases', (req, resp) ->
  phrase = req.body.phrase.text
  if phrase?
    sig = PhraseSignature.fromPhrase(phrase, ngramLength).toSignature()
    resp.redirect("/phrase/#{sig}")
  else
    resp.send(422, "missing text from body")
)

app.get('/phrases/:sig', (req, resp) ->
  sig = PhraseSignature.fromSignature(req.params.sig)
  hrefsForNGrams = {}
  for nGram in sig.toNGrams()
    hrefsForNGrams[nGram] = "/ngrams/#{nGram}"
  regionFinder.nearest(sig, 10, (nearest) ->
    resp.send({
      signature: sig.toSignature()
      nGrams: hrefsForNGrams
      nearest: "/regions/#{region.hash}" for region in nearest
    })
  )
)

app.get('/ngrams', (req, resp) ->
  tweetCounts.overallNGramCounts((results) ->
    resp.send(results)
  )
)

app.get('/ngrams/:ngram', (req, resp) ->
  tweetCounts.countRegionsInWhichNGramOccurs(req.params.ngram, (result) ->
    resp.send({
      nGram: result.ngram
      regions: {
        count: result.regions
      }
    })
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