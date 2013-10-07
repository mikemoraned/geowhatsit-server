// Generated by CoffeeScript 1.6.1
(function() {
  var LatLon, RedisTweetCounts, TweetCountsFactory, assert, fillInNullForError, latLonAsGeoHash, latLonExample, name, precision, text, vows,
    _this = this;

  vows = require('vows');

  assert = require('assert');

  RedisTweetCounts = require('../../lib/RedisTweetCounts');

  TweetCountsFactory = require('../../lib/TweetCountsFactory');

  LatLon = require('../../lib/LatLon');

  name = "TweetCountsTest_" + (Math.random());

  precision = 4;

  latLonExample = new LatLon(57.64911, 10.40744);

  latLonAsGeoHash = "u4pruydqqvj".slice(0, precision);

  text = {
    nGrams: ["aa", "bb"],
    length: 2
  };

  fillInNullForError = function(callback) {
    return function(realResult) {
      return callback(null, realResult);
    };
  };

  vows.describe('TweetCounts').addBatch({
    'when using TweetCounts impl from factory': {
      topic: TweetCountsFactory.create(name, precision),
      'when new text is added': {
        topic: function(tweetCounts) {
          tweetCounts.add(latLonExample, text);
          return text;
        },
        'when we ask for overallNGramCounts': {
          topic: function(text, tweetCounts) {
            tweetCounts.overallNGramCounts(fillInNullForError(this.callback));
          },
          'all ngrams have one tweet registered': function(counts) {
            var countForNGram, item, _i, _len;
            countForNGram = {};
            for (_i = 0, _len = counts.length; _i < _len; _i++) {
              item = counts[_i];
              countForNGram[item.ngram] = item.tweets;
            }
            assert.equal(countForNGram["2:aa"], 1);
            return assert.equal(countForNGram["2:bb"], 1);
          }
        },
        'when we ask for tweetCountsByRegionForNGrams': {
          topic: function(text, tweetCounts) {
            tweetCounts.tweetCountsByRegionForNGrams(text.nGrams, fillInNullForError(this.callback));
          },
          'each ngram has only one region': function(results) {
            var item, regionCountForNGram, _i, _len;
            regionCountForNGram = {};
            for (_i = 0, _len = results.length; _i < _len; _i++) {
              item = results[_i];
              regionCountForNGram[item.ngram] = item.regions.length;
            }
            assert.equal(regionCountForNGram["aa"], 1);
            return assert.equal(regionCountForNGram["bb"], 1);
          },
          'each ngram maps to geohash for latLon, with expected precision': function(results) {
            var geoHash, item, regions, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = results.length; _i < _len; _i++) {
              item = results[_i];
              regions = item.regions;
              assert.equal(regions.length, 1);
              geoHash = regions[0].region;
              _results.push(assert.equal(geoHash, latLonAsGeoHash));
            }
            return _results;
          }
        },
        'when we ask to dumpToArchive': {
          topic: function(text, tweetCounts) {
            tweetCounts.dumpToArchive(fillInNullForError(this.callback));
          },
          'all nGrams and geoHashes appear': function(archive) {
            var expected;
            expected = [
              {
                nGram: 'bb',
                region: 'u4pr',
                tweets: 1
              }, {
                nGram: 'aa',
                region: 'u4pr',
                tweets: 1
              }
            ];
            return assert.deepEqual(archive, expected);
          }
        }
      }
    }
  })["export"](module);

}).call(this);
