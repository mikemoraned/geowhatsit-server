// Generated by CoffeeScript 1.6.1
(function() {
  var LatLon, PhraseSignature, SurprisingNGrams, TFIDF, TweetCountsFactory, app, express, geohash, ngramLength, port, surprising, tfidf, tweetCounts, _;

  express = require("express");

  app = express();

  app.use(express.logger());

  app.use(express.bodyParser());

  _ = require('underscore');

  geohash = require('ngeohash');

  LatLon = require("./lib/LatLon");

  TweetCountsFactory = require("./lib/TweetCountsFactory");

  SurprisingNGrams = require("./lib/SurprisingNGrams");

  TFIDF = require("./lib/TFIDF");

  PhraseSignature = require("./lib/PhraseSignature");

  ngramLength = 2;

  tweetCounts = TweetCountsFactory.create(ngramLength);

  surprising = new SurprisingNGrams(tweetCounts);

  tfidf = new TFIDF(tweetCounts);

  app.all('*', function(req, resp, next) {
    resp.header("Access-Control-Allow-Origin", "*");
    resp.header("Access-Control-Allow-Headers", "X-Requested-With");
    return next();
  });

  app.get('/', function(req, resp) {
    return resp.send('Hello World!');
  });

  app.get('/counts.json', function(req, resp) {
    return tweetCounts.dump(function(dumped) {
      return resp.send(dumped);
    });
  });

  app.get('/regions', function(req, resp) {
    return tweetCounts.summariseRegions(function(results) {
      var expanded, region, result;
      expanded = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = results.length; _i < _len; _i++) {
          result = results[_i];
          region = result.region;
          _results.push({
            name: region.hash,
            geo: {
              center: region.center,
              bbox: region.boundingBox()
            },
            summary: result.summary,
            ngrams: {
              href: "/regions/" + region.hash + "/ngrams"
            },
            hrefs: {
              ngrams: "/regions/" + region.hash + "/ngrams",
              surprising: "/regions/" + region.hash + "/ngrams/surprising",
              tfidf: "/regions/" + region.hash + "/ngrams/tfidf"
            }
          });
        }
        return _results;
      })();
      return resp.send(expanded);
    });
  });

  app.get('/regions/:geohash/ngrams', function(req, resp) {
    return tweetCounts.ngramCountsForRegion(req.params.geohash, function(results) {
      return resp.send(results);
    });
  });

  app.get('/regions/:geohash/ngrams/surprising', function(req, resp) {
    return surprising.surprisingNGramsForRegion(req.params.geohash, function(results) {
      return resp.send(results);
    });
  });

  app.get('/regions/:geohash/ngrams/tfidf', function(req, resp) {
    return tfidf.ngramsForRegionOrderedByScore(req.params.geohash, function(results) {
      return resp.send(results);
    });
  });

  app.get('/phrases', function(req, resp) {
    return resp.send('<!doctype html>\n<html lang=en>\n<meta charset=utf-8>\n<title>enter phrase</title>\n<p>enter phrase:</p>\n<form method="POST" >\n  <textarea name="phrase[text]"></textarea>\n  <input type="submit"/>\n</form>');
  });

  app.post('/phrases', function(req, resp) {
    var phrase, sig;
    phrase = req.body.phrase.text;
    if (phrase != null) {
      sig = PhraseSignature.fromPhrase(phrase, ngramLength).toSignature();
      return resp.redirect("/phrase/" + sig);
    } else {
      return resp.send(422, "missing text from body");
    }
  });

  app.get('/phrases/:sig', function(req, resp) {
    var hrefsForNGrams, nGram, sig, _i, _len, _ref;
    sig = PhraseSignature.fromSignature(req.params.sig);
    hrefsForNGrams = {};
    _ref = sig.toNGrams();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      nGram = _ref[_i];
      hrefsForNGrams[nGram] = "/ngrams/" + nGram;
    }
    return resp.send({
      signature: sig.toSignature(),
      nGrams: hrefsForNGrams
    });
  });

  app.get('/ngrams', function(req, resp) {
    return tweetCounts.overallNGramCounts(function(results) {
      return resp.send(results);
    });
  });

  app.get('/ngrams/:ngram', function(req, resp) {
    return tweetCounts.countRegionsInWhichNGramOccurs(req.params.ngram, function(result) {
      return resp.send({
        nGram: result.ngram,
        regions: {
          count: result.regions
        }
      });
    });
  });

  app.get('/counts/grouped-by-geohash/precision-:precision.json', function(req, resp) {
    return tweetCounts.dump(function(dumped) {
      var byGeoHash, counts;
      byGeoHash = _.countBy(dumped.counts, function(entry) {
        return geohash.encode(entry.lat_lon.latitude, entry.lat_lon.longitude, req.params.precision);
      });
      counts = _.map(byGeoHash, function(count, encoded) {
        return {
          'lat_lon': geohash.decode(encoded),
          'count': count
        };
      });
      return resp.send({
        'total': dumped.total,
        'counts': counts
      });
    });
  });

  port = process.env.PORT || 5000;

  app.listen(port, function() {
    return console.log("Listening on " + port);
  });

}).call(this);
