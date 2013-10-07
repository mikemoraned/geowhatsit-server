vows = require('vows')
assert = require('assert')

RedisTweetCounts = require('../../lib/RedisTweetCounts')
TweetCountsFactory = require('../../lib/TweetCountsFactory')
LatLon = require('../../lib/LatLon')

name = "TweetCountsTest_#{Math.random()}"
precision = 4

latLonExample = new LatLon(57.64911,10.40744)
latLonAsGeoHash = "u4pruydqqvj".slice(0, precision)

text =
  nGrams: ["aa","bb"]
  length: 2



fillInNullForError = (callback) =>
  (realResult) =>
    callback(null, realResult)

vows
  .describe('TweetCounts')
  .addBatch
    'when using TweetCounts impl from factory':
      topic: TweetCountsFactory.create(name, precision)
      'when new text is added':
        topic: (tweetCounts) ->
          tweetCounts.add(latLonExample, text)
          text
        'when we ask for overallNGramCounts':
          topic: (text, tweetCounts) ->
            tweetCounts.overallNGramCounts(fillInNullForError(this.callback))
            return
          'all ngrams have one tweet registered': (counts) ->
            countForNGram = {}
            for item in counts
              countForNGram[item.ngram] = item.tweets
            assert.equal countForNGram["2:aa"], 1
            assert.equal countForNGram["2:bb"], 1
        'when we ask for tweetCountsByRegionForNGrams':
          topic: (text, tweetCounts) ->
            tweetCounts.tweetCountsByRegionForNGrams(text.nGrams, fillInNullForError(this.callback))
            return
          'each ngram has only one region': (results) ->
            regionCountForNGram = {}
            for item in results
              regionCountForNGram[item.ngram] = item.regions.length
            assert.equal regionCountForNGram["aa"], 1
            assert.equal regionCountForNGram["bb"], 1
          'each ngram maps to geohash for latLon, with expected precision': (results) ->
            for item in results
              regions = item.regions
              assert.equal regions.length, 1
              geoHash = regions[0].region
              assert.equal geoHash, latLonAsGeoHash
        'when we ask to dumpToArchive':
          topic: (text, tweetCounts) ->
            tweetCounts.dumpToArchive(fillInNullForError(this.callback))
            return
          'all nGrams and geoHashes appear': (archive) ->
            expected = [
              {
                nGram: 'bb'
                region: 'u4pr'
                tweets: 1
              },
              {
                nGram: 'aa'
                region: 'u4pr'
                tweets: 1
              }
            ]
            assert.deepEqual archive, expected

  .export(module)

