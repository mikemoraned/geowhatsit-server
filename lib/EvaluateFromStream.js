// Generated by CoffeeScript 1.6.1
(function() {
  var EvaluateFromStream, LatLon, PhraseSignature, Stream, request, url, urlencode,
    _this = this,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  url = require("url");

  urlencode = require("urlencode");

  request = require("request");

  LatLon = require("./LatLon");

  Stream = require("./Stream");

  PhraseSignature = require("./PhraseSignature");

  EvaluateFromStream = (function(_super) {

    __extends(EvaluateFromStream, _super);

    function EvaluateFromStream(baseURL, twitter, restartAfterSeconds) {
      var _this = this;
      this.baseURL = baseURL;
      this.collectMetrics = function(collector) {
        return EvaluateFromStream.prototype.collectMetrics.apply(_this, arguments);
      };
      this.dumpStats = function() {
        return EvaluateFromStream.prototype.dumpStats.apply(_this, arguments);
      };
      this.incRegionCounts = function(name) {
        return EvaluateFromStream.prototype.incRegionCounts.apply(_this, arguments);
      };
      this.incStat = function(name) {
        return EvaluateFromStream.prototype.incStat.apply(_this, arguments);
      };
      this.ignoreTweetOnError = function(e, data) {
        return EvaluateFromStream.prototype.ignoreTweetOnError.apply(_this, arguments);
      };
      this.handleData = function(data) {
        return EvaluateFromStream.prototype.handleData.apply(_this, arguments);
      };
      EvaluateFromStream.__super__.constructor.call(this, twitter, restartAfterSeconds);
      this.regionCounts = {};
      this.stats = {
        seen: 0,
        has_geo: 0,
        evaluated: 0,
        correct: 0
      };
    }

    EvaluateFromStream.prototype.handleData = function(data) {
      var latLon, locationURL, phraseURL, sig,
        _this = this;
      this.incStat("seen");
      if ((data.geo != null) && (data.geo.coordinates != null)) {
        this.incStat("has_geo");
        latLon = new LatLon(data.geo.coordinates[0], data.geo.coordinates[1]);
        sig = PhraseSignature.fromPhrase(data.text, 2);
        try {
          locationURL = url.resolve(this.baseURL, "/locations/" + latLon.latitude + "," + latLon.longitude);
          phraseURL = url.resolve(this.baseURL, "/phrases/" + (urlencode(sig.toSignature())));
          console.log("location: " + locationURL + ", phrase: " + phraseURL);
          return request(locationURL, function(error, response, body) {
            var expectedRegion;
            if (!error && response.statusCode === 200) {
              try {
                expectedRegion = JSON.parse(body).region;
                _this.incRegionCounts(expectedRegion.name);
                return request(phraseURL, function(error, response, body) {
                  var algorithm, correct, nearest, results, some_correct, top;
                  if (!error && response.statusCode === 200) {
                    try {
                      nearest = JSON.parse(body).nearest;
                      if (nearest != null) {
                        _this.incStat("evaluated");
                        some_correct = false;
                        for (algorithm in nearest) {
                          results = nearest[algorithm];
                          top = results[0];
                          correct = expectedRegion.name === top.name;
                          some_correct = correct || some_correct;
                          console.log("" + expectedRegion.name + "," + top.name + "," + correct);
                          if (correct) {
                            _this.incStat("algorithm." + algorithm + ".correct");
                          }
                        }
                        if (some_correct) {
                          return _this.incStat("correct");
                        }
                      }
                    } catch (e) {
                      return _this.ignoreTweetOnError(e, data);
                    }
                  }
                });
              } catch (e) {
                return _this.ignoreTweetOnError(e, data);
              }
            }
          });
        } catch (e) {
          return this.ignoreTweetOnError(e, data);
        }
      }
    };

    EvaluateFromStream.prototype.ignoreTweetOnError = function(e, data) {
      console.dir(e);
      return console.dir(("ignoring tweet: https://twitter.com/" + data.user.screen_name + "/status/" + data.id_str + ", text: \"") + data.text + "\"");
    };

    EvaluateFromStream.prototype.incStat = function(name) {
      if (this.stats[name] != null) {
        return this.stats[name] = this.stats[name] + 1;
      } else {
        return this.stats[name] = 1;
      }
    };

    EvaluateFromStream.prototype.incRegionCounts = function(name) {
      if (this.regionCounts[name] != null) {
        return this.regionCounts[name] = this.regionCounts[name] + 1;
      } else {
        return this.regionCounts[name] = 1;
      }
    };

    EvaluateFromStream.prototype.dumpStats = function() {
      return console.dir(this.stats);
    };

    EvaluateFromStream.prototype.collectMetrics = function(collector) {
      var key, value, _ref, _results;
      this.dumpStats();
      _ref = this.stats;
      _results = [];
      for (key in _ref) {
        value = _ref[key];
        _results.push(collector.send("evaluate." + key, value));
      }
      return _results;
    };

    return EvaluateFromStream;

  })(Stream);

  module.exports = EvaluateFromStream;

}).call(this);
