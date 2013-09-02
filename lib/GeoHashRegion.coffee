geohash = require('ngeohash')
LatLon = require('./LatLon')

class GeoHashRegion
  constructor: (@center, @error, @hash) ->

  toHash: (precision) ->
    geohash.encode(@center.latitude, @center.longitude, precision)

  boundingBox: () ->
    # note: just being naive here and not handling edge-cases at bounds of longitude and latitude
    # i.e. just treating lat and lon as x and y axes
    {
      topLeft: new LatLon(@center.latitude - @error.latitude, @center.longitude - @error.longitude)
      bottomRight: new LatLon(@center.latitude + @error.latitude, @center.longitude + @error.longitude)
    }

  @fromPointInRegion: (latLon, precision) ->
    hash = geohash.encode(latLon.latitude, latLon.longitude, precision)
    GeoHashRegion.fromHash(hash)

  @fromHash: (hash) ->
    decoded = geohash.decode(hash)
    center = new LatLon(decoded.latitude, decoded.longitude)
    new GeoHashRegion(center, decoded.error, hash)

module.exports = GeoHashRegion