geohash = require('ngeohash')
LatLon = require('./LatLon')

class GeoHashRegion
  constructor: (@center, @hash) ->

  toHash: (precision) ->
    geohash.encode(@center.latitude, @center.longitude, precision)

  @fromPointInRegion: (latLon, precision) ->
    hash = geohash.encode(latLon.latitude, latLon.longitude, precision)
    GeoHashRegion.fromHash(hash)

  @fromHash: (hash) ->
    decoded = geohash.decode(hash)
    center = new LatLon(decoded.latitude, decoded.longitude)
    new GeoHashRegion(center, hash)

module.exports = GeoHashRegion