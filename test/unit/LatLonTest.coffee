vows = require('vows')
assert = require('assert')

LatLon = require('../../lib/LatLon')

vows
  .describe('LatLon')
  .addBatch
    'when given lat/lon':
      topic: new LatLon(57.64911,10.40744),
      'can convert to geohash with desired precision': (latLon) ->
        geoHash = latLon.toGeoHash(11)
        assert.equal 11, geoHash.length
        assert.equal "u4pruydqqvj", geoHash
      'reducing precision gives geohash which is prefix of higher precision geohash': (latLon) ->
        geoHash = latLon.toGeoHash(5)
        assert.equal "u4pru", geoHash

    'when given geohash':
      topic: "u4pruydqqvj",
      'can convert back to lat/lon': (geoHash) ->
        latLon = LatLon.fromGeoHash(geoHash)
        assert.equal 57.64911, latLon.latitude.toFixed(5)
        assert.equal 10.40744, latLon.longitude.toFixed(5)

  .export(module)

