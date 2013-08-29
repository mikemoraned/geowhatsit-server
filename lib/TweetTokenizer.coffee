_ = require('underscore')
NGrams = require("natural").NGrams

class TweetTokenizer

  constructor: (@length) ->

  nGrams: (text) =>
    if text.length == 0
      {
      'length' : @length
      'nGrams': []
      }
    else
      words = text.toLowerCase().split(/\s+/)
      nGramsForEachWord = _.flatten((NGrams.ngrams(word.split(""), @length) for word in words), true)
      nGrams = _.uniq(_.map(nGramsForEachWord, (d) -> d.join("")))
      {
      'length' : @length
      'nGrams': nGrams
      }

module.exports = TweetTokenizer
