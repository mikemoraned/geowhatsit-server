// Generated by CoffeeScript 1.6.1
(function() {
  var NGrams, PhraseSignature, _;

  _ = require('underscore');

  NGrams = require("natural").NGrams;

  PhraseSignature = (function() {

    function PhraseSignature(sortedNGrams) {
      this.sortedNGrams = sortedNGrams;
    }

    PhraseSignature.fromPhrase = function(phrase, ngramLength) {
      var nGramsForEachWord, sortedNGrams, word, words;
      words = phrase.toLowerCase().split(/\s+/);
      nGramsForEachWord = _.flatten((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = words.length; _i < _len; _i++) {
          word = words[_i];
          _results.push(NGrams.ngrams(word.split(""), ngramLength));
        }
        return _results;
      })(), true);
      sortedNGrams = _.chain(nGramsForEachWord).map(function(d) {
        return d.join("");
      }).uniq().sortBy(function(d) {
        return d;
      }).value();
      return new PhraseSignature(sortedNGrams);
    };

    PhraseSignature.fromSignature = function(sig) {
      return new PhraseSignature(_.sortBy(sig.split(/\-/), function(d) {
        return d;
      }));
    };

    PhraseSignature.prototype.toSignature = function() {
      return this.sortedNGrams.join('-');
    };

    PhraseSignature.prototype.toNGrams = function() {
      return this.sortedNGrams;
    };

    return PhraseSignature;

  })();

  module.exports = PhraseSignature;

}).call(this);
