// Generated by CoffeeScript 1.6.1
(function() {
  var Factory, HostedGraphite, LocalGraphite, dgram, net,
    _this = this;

  dgram = require('dgram');

  net = require('net');

  LocalGraphite = (function() {

    function LocalGraphite() {
      var _this = this;
      this.send = function(name, value) {
        return LocalGraphite.prototype.send.apply(_this, arguments);
      };
      this.appName = "geowhatsit";
    }

    LocalGraphite.prototype.send = function(name, value) {
      var message, stream, timestamp,
        _this = this;
      timestamp = (new Date().getTime() / 1000).toFixed(0);
      message = "" + this.appName + "." + name + " " + value + " " + timestamp;
      stream = new net.Stream();
      stream.addListener('connect', function() {
        stream.write(message);
        stream.write("\n");
        return stream.end();
      });
      stream.addListener('error', function(e) {
        return console.log("Dropped \"" + message + "\": " + e);
      });
      return stream.connect(2003, "localhost");
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
      message = new Buffer("" + this.apikey + "." + name + " " + value + "\n");
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
