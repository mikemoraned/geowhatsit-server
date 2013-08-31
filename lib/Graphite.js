// Generated by CoffeeScript 1.6.1
(function() {
  var Factory, HostedGraphite, LocalGraphite, dgram,
    _this = this;

  dgram = require('dgram');

  LocalGraphite = (function() {

    function LocalGraphite() {
      var _this = this;
      this.send = function(name, value) {
        return LocalGraphite.prototype.send.apply(_this, arguments);
      };
      this.appName = "geowhatsit";
    }

    LocalGraphite.prototype.send = function(name, value) {
      var client, message, timestamp;
      timestamp = (new Date().getTime() / 1000).toFixed(0);
      message = new Buffer("" + this.appName + "." + name + " " + value + " " + timestamp + "\n");
      client = dgram.createSocket("udp4");
      return client.send(message, 0, message.length, 2004, "localhost", function(err, bytes) {
        return client.close();
      });
    };

    return LocalGraphite;

  })();

  HostedGraphite = (function() {

    function HostedGraphite(apikey) {
      var _this = this;
      this.apikey = apikey;
      this.send = function(name, value) {
        return HostedGraphite.prototype.send.apply(_this, arguments);
      };
    }

    HostedGraphite.prototype.send = function(name, value) {
      var client, message;
      message = new Buffer(this.apikey + ("." + name + " " + value + "\n"));
      client = dgram.createSocket("udp4");
      return client.send(message, 0, message.length, 2003, "carbon.hostedgraphite.com", function(err, bytes) {
        return client.close();
      });
    };

    return HostedGraphite;

  })();

  Factory = (function() {

    function Factory() {}

    Factory.initializeInHeroku = function() {
      var apikey;
      apikey = process.env.HOSTEDGRAPHITE_APIKEY;
      if (apikey != null) {
        console.log("Using hosted graphite, api key: " + apikey);
        return new HostedGraphite(apikey);
      } else {
        console.log("Using local Graphite");
        return new LocalGraphite();
      }
    };

    return Factory;

  })();

  module.exports = Factory;

}).call(this);