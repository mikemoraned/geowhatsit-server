express = require("express")
thisPackage = require("./package.json")
app = express()
app.use(express.logger())
app.use(express.bodyParser())

_ = require('underscore')
geohash = require('ngeohash')

LatLon = require("./lib/LatLon")
GeoHashRegion = require("./lib/GeoHashRegion")

TweetCountsFactory = require("./lib/TweetCountsFactory")
TFIDF = require("./lib/TFIDF")

PhraseSignature = require("./lib/PhraseSignature")
NearestRegionFinder = require("./lib/NearestRegionFinder")

ngramLength = 2
tweetCounts = TweetCountsFactory.create("prod", ngramLength)
regionFinder = new NearestRegionFinder(tweetCounts)
tfidf = new TFIDF(tweetCounts)

app.all('*', (req, resp, next) ->
  resp.header("Access-Control-Allow-Origin", "*")
  resp.header("Access-Control-Allow-Headers", "X-Requested-With")
  next()
)

app.get('/', (req, resp) ->
  resp.send("""
              <!doctype html>
              <html lang=en>
              <meta charset=utf-8>
              <h1>GeoWhatsit version #{thisPackage.version}</h1>
              For info, see: <a href="https://github.com/mikemoraned/geowhatsit-server">geowhatsit-server</a> on github.
              """)
)
app.get('/counts.json', (req, resp) ->
  tweetCounts.dump((dumped) ->
    resp.send(dumped)
  )
)

app.get('/locations/:lat,:lon', (req, resp) ->
  location = new LatLon(parseFloat(req.params.lat),parseFloat(req.params.lon))
  region = GeoHashRegion.fromPointInRegion(location,2)
  resp.send({
    location: location
    region: {
      name: region.hash
      href: "/regions/#{region.hash}"
    }
  })
)

expandSummary = (result) ->
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
      ngrams: "/regions/#{region.hash}/ngrams"
      tfidf: "/regions/#{region.hash}/ngrams/tfidf"
    }
  }

app.get('/regions', (req, resp) ->
  tweetCounts.summariseRegions((results) ->
    resp.send(expandSummary(result) for result in results)
  )
)

app.get('/regions/:geohash', (req, resp) ->
  tweetCounts.summariseRegion(req.params.geohash, (result) ->
    if result?
      resp.send(expandSummary(result))
    else
      resp.send(404)
  )
)

app.get('/regions/:geohash/ngrams', (req, resp) ->
  tweetCounts.ngramCountsForRegion(req.params.geohash, (results) ->
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
  regionFinder.nearest(sig, 10, (nearestRegionsByAlgorithm) ->
    nearest = {}
    for algorithm, nearestRegions of nearestRegionsByAlgorithm
      nearest[algorithm] = for region in nearestRegions
        {
          name: region.hash
          href: "/regions/#{region.hash}"
        }

    resp.send({
      signature: sig.toSignature()
      nGrams: hrefsForNGrams
      nearest: nearest
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

port = process.env.PORT || 5000
app.listen(port, () ->
  console.log("Listening on " + port)
)