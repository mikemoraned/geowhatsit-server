geohash = require('ngeohash')

class LatLon
  constructor: (lat, lon) ->
    @latitude = lat
    @longitude = lon

  toId: () ->
    "#{@latitude},#{@longitude}"

  toGeoHash: (precision) ->
    geohash.encode(@latitude, @longitude, precision)

  @fromId: (id) ->
    [latS, lonS] = id.split(",")
    new LatLon(parseFloat(latS), parseFloat(lonS))

  @fromGeoHash: (geoHash) ->
    decoded = geohash.decode(geoHash)
    new LatLon(decoded.latitude, decoded.longitude)

module.exports = LatLon
