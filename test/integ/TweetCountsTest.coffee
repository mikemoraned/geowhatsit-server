vows = require('vows')
assert = require('assert')

RedisTweetCounts = require('../../lib/RedisTweetCounts')
TweetCountsFactory = require('../../lib/TweetCountsFactory')
LatLon = require('../../lib/LatLon')

latLonExample = new LatLon(57.64911,10.40744)

text =
  nGrams: ["aa","bb"]
  length: 2

name = "TweetCountsTest_#{Math.random()}"
precision = 2

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
        'when we ask for overall ngram counts':
          topic: (text, tweetCounts) ->
            tweetCounts.overallNGramCounts(fillInNullForError(this.callback))
            return
          'all ngrams have one tweet registered': (counts) ->
            countForNGram = {}
            for item in counts
              countForNGram[item.ngram] = item.tweets
            assert.equal countForNGram["2:aa"], 1
            assert.equal countForNGram["2:bb"], 1

  .export(module)

