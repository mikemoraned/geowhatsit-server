_ = require('underscore')
NGrams = require("natural").NGrams

class PhraseSignature
  constructor: (@sortedNGrams) ->

  @fromPhrase: (phrase, ngramLength) ->
    words = phrase.toLowerCase().split(/\s+/)
    nGramsForEachWord = _.flatten((NGrams.ngrams(word.split(""), ngramLength) for word in words), true)
    sortedNGrams =
      _.chain(nGramsForEachWord)
        .map((d) -> d.join(""))
        .uniq()
        .sortBy((d) -> d)
        .value()
    new PhraseSignature(sortedNGrams)

  @fromSignature: (sig) ->
    new PhraseSignature(_.sortBy(sig.split(","), (d) -> d))

  toSignature: () ->
    @sortedNGrams.join(",")

  toNGrams: () ->
    @sortedNGrams

module.exports = PhraseSignature