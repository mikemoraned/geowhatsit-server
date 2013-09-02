geohash = require('ngeohash')

class LatLon
  constructor: (lat, lon) ->
    @latitude = lat
    @longitude = lon

  toId: () ->
    "#{@latitude},#{@longitude}"

  @fromId: (id) ->
    [latS, lonS] = id.split(",")
    new LatLon(parseFloat(latS), parseFloat(lonS))

module.exports = LatLon
