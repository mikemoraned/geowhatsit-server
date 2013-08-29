vows = require('vows')
assert = require('assert')

TweetTokenizer = require('../../lib/TweetTokenizer')

vows
  .describe('TweetTokenizer')
  .addBatch
    'when given normal english word':
      topic: "some",
      'can convert to bigrams': (text) ->
        nGrams = new TweetTokenizer(2).nGrams(text)
        assert.equal nGrams.length, 2
        assert.deepEqual nGrams.nGrams, ['so','om','me']

    'when given normal english phrase':
      topic: "some text",
      'can convert words into bigrams': (text) ->
        nGrams = new TweetTokenizer(2).nGrams(text)
        assert.equal nGrams.length, 2
        assert.deepEqual nGrams.nGrams, ['so','om','me','te','ex','xt']
      'can convert words into trigrams': (text) ->
        nGrams = new TweetTokenizer(3).nGrams(text)
        assert.equal nGrams.length, 3
        assert.deepEqual nGrams.nGrams, ['som','ome','tex','ext']

    'when given normal english phrase with repeated bigrams':
      topic: "some come",
      'only shows repeated bigrams once': (text) ->
        nGrams = new TweetTokenizer(2).nGrams(text)
        assert.equal nGrams.length, 2
        assert.deepEqual nGrams.nGrams, ['so','om','me','co']

    'when given mixed-case':
      topic: "soMe tExt",
      'normalises all bigrams into lowercase': (text) ->
        nGrams = new TweetTokenizer(2).nGrams(text)
        assert.equal nGrams.length, 2
        assert.deepEqual nGrams.nGrams, ['so','om','me','te','ex','xt']

    'when given empty string':
      topic: "",
      'returns no bigrams': (text) ->
        nGrams = new TweetTokenizer(2).nGrams(text)
        assert.equal nGrams.length, 2
        assert.deepEqual nGrams.nGrams, []

  .export(module)

