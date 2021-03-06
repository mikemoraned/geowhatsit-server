// Generated by CoffeeScript 1.6.1
(function() {
  var PhraseSignature, assert, vows;

  vows = require('vows');

  assert = require('assert');

  PhraseSignature = require('../../lib/PhraseSignature');

  vows.describe('PhraseSignature').addBatch({
    'when created from non-empty phrase': {
      topic: "thrifty mick",
      'reduces it to sorted ngram signature': function(phrase) {
        return assert.equal("ck-ft-hr-ic-if-mi-ri-th-ty", PhraseSignature.fromPhrase(phrase, 2).toSignature());
      },
      'can get as ngram array': function(phrase) {
        return assert.deepEqual(["ck", "ft", "hr", "ic", "if", "mi", "ri", "th", "ty"], PhraseSignature.fromPhrase(phrase, 2).toNGrams());
      }
    },
    'when created from sorted signature': {
      topic: "ab-bc-cd",
      'can parse and then round-trip back to sorted ngrams ': function(sorted) {
        return assert.equal("ab-bc-cd", PhraseSignature.fromSignature(sorted).toSignature());
      },
      'can get as ngram array': function(sorted) {
        return assert.deepEqual(["ab", "bc", "cd"], PhraseSignature.fromSignature(sorted).toNGrams());
      }
    },
    'when created from unsorted signature': {
      topic: "bc-ab-cd",
      'can normalize to sorted ngrams': function(unsorted) {
        return assert.equal("ab-bc-cd", PhraseSignature.fromSignature(unsorted).toSignature());
      },
      'can get as ngram array': function(unsorted) {
        return assert.deepEqual(["ab", "bc", "cd"], PhraseSignature.fromSignature(unsorted).toNGrams());
      }
    }
  })["export"](module);

}).call(this);
