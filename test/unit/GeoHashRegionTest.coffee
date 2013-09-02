vows = require('vows')
assert = require('assert')

GeoHashRegion = require('../../lib/GeoHashRegion')
LatLon = require('../../lib/LatLon')

vows
  .describe('GeoHash')
  .addBatch
    'when given lat/lon point':
      topic: new LatLon(57.64911,10.40744),
      'can find covering geohash region with desired precision': (latLon) ->
        region = GeoHashRegion.fromPointInRegion(latLon, 11)
        assert.equal 11, region.hash.length
        assert.equal "u4pruydqqvj", region.hash
      'reducing precision gives geohash region which is prefix of higher precision geohash region': (latLon) ->
        region = GeoHashRegion.fromPointInRegion(latLon, 5)
        assert.equal "u4pru", region.hash

    'when given geohash':
      topic: "u4pruydqqvj",
      'can round-trip back to lat/lon center': (geoHash) ->
        region = GeoHashRegion.fromHash(geoHash)
        assert.equal 57.64911, region.center.latitude.toFixed(5)
        assert.equal 10.40744, region.center.longitude.toFixed(5)

  .export(module)

