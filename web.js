// Generated by CoffeeScript 1.6.1
(function() {
  var GeoHashRegion, LatLon, NearestRegionFinder, PhraseSignature, SurprisingNGrams, TFIDF, TweetCountsFactory, app, expandSummary, express, geohash, ngramLength, port, regionFinder, surprising, tfidf, thisPackage, tweetCounts, _;

  express = require("express");

  thisPackage = require("./package.json");

  app = express();

  app.use(express.logger());

  app.use(express.bodyParser());

  _ = require('underscore');

  geohash = require('ngeohash');

  LatLon = require("./lib/LatLon");

  GeoHashRegion = require("./lib/GeoHashRegion");

  TweetCountsFactory = require("./lib/TweetCountsFactory");

  SurprisingNGrams = require("./lib/SurprisingNGrams");

  TFIDF = require("./lib/TFIDF");

  PhraseSignature = require("./lib/PhraseSignature");

  NearestRegionFinder = require("./lib/NearestRegionFinder");

  ngramLength = 2;

  tweetCounts = TweetCountsFactory.create(ngramLength);

  surprising = new SurprisingNGrams(tweetCounts);

  regionFinder = new NearestRegionFinder(tweetCounts);

  tfidf = new TFIDF(tweetCounts);

  app.all('*', function(req, resp, next) {
    resp.header("Access-Control-Allow-Origin", "*");
    resp.header("Access-Control-Allow-Headers", "X-Requested-With");
    return next();
  });

  app.get('/', function(req, resp) {
    return resp.send("Version: " + thisPackage.version);
  });

  app.get('/counts.json', function(req, resp) {
    return tweetCounts.dump(function(dumped) {
      return resp.send(dumped);
    });
  });

  app.get('/locations/:lat,:lon', function(req, resp) {
    var location, region;
    location = new LatLon(parseFloat(req.params.lat), parseFloat(req.params.lon));
    region = GeoHashRegion.fromPointInRegion(location, 2);
    return resp.send({
      location: location,
      region: {
        name: region.hash,
        href: "/regions/" + region.hash
      }
    });
  });

  expandSummary = function(result) {
    var region;
    region = result.region;
    return {
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
    };
  };

  app.get('/regions', function(req, resp) {
    return tweetCounts.summariseRegions(function(results) {
      var result;
      return resp.send((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = results.length; _i < _len; _i++) {
          result = results[_i];
          _results.push(expandSummary(result));
        }
        return _results;
      })());
    });
  });

  app.get('/regions/:geohash', function(req, resp) {
    return tweetCounts.summariseRegion(req.params.geohash, function(result) {
      if (result != null) {
        return resp.send(expandSummary(result));
      } else {
        return resp.send(404);
      }
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
    return regionFinder.nearest(sig, 10, function(nearestRegionsByAlgorithm) {
      var algorithm, nearest, nearestRegions, region;
      nearest = {};
      for (algorithm in nearestRegionsByAlgorithm) {
        nearestRegions = nearestRegionsByAlgorithm[algorithm];
        nearest[algorithm] = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = nearestRegions.length; _j < _len1; _j++) {
            region = nearestRegions[_j];
            _results.push({
              name: region.hash,
              href: "/regions/" + region.hash
            });
          }
          return _results;
        })();
      }
      return resp.send({
        signature: sig.toSignature(),
        nGrams: hrefsForNGrams,
        nearest: nearest
      });
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

  port = process.env.PORT || 5000;

  app.listen(port, function() {
    return console.log("Listening on " + port);
  });

}).call(this);
