// Generated by CoffeeScript 1.6.1
(function() {
  var BySumOfTFIDFScore, GeoHashRegion, PhraseSignature, TFIDF, _;

  _ = require('underscore');

  TFIDF = require("../TFIDF");

  GeoHashRegion = require("../GeoHashRegion");

  PhraseSignature = require("../PhraseSignature");

  BySumOfTFIDFScore = (function() {

    function BySumOfTFIDFScore(tweetCounts) {
      this.tweetCounts = tweetCounts;
      this.tfidf = new TFIDF(this.tweetCounts);
    }

    BySumOfTFIDFScore.prototype.nearest = function(signature, limit, callback) {
      var ngrams,
        _this = this;
      ngrams = signature.toNGrams();
      return this.tfidf.scoredRegionsForNGrams(ngrams, function(scored) {
        var entry, score, summed;
        summed = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = scored.length; _i < _len; _i++) {
            entry = scored[_i];
            _results.push({
              region: entry.region,
              score: score = _.chain(entry.scores).pluck("tf_idf").reduce(function(m, d) {
                return m + d;
              }).value()
            });
          }
          return _results;
        })();
        return callback(_.chain(summed).sortBy(function(d) {
          return d.score;
        }).first(limit).pluck("region").filter(function(d) {
          return d !== "[object Object]";
        }).map(function(d) {
          return GeoHashRegion.fromHash(d);
        }).value());
      });
    };

    return BySumOfTFIDFScore;

  })();

  module.exports = BySumOfTFIDFScore;

}).call(this);
