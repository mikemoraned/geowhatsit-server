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

    'when created from known geohash':
      topic: GeoHashRegion.fromHash("qq"),
      'can determine bounding box': (region) ->
        bb = region.boundingBox()
        assert.equal -5.625, bb.topLeft.latitude.toFixed(3)
        assert.equal 101.25, bb.topLeft.longitude.toFixed(2)
        assert.equal -11.25, bb.bottomRight.latitude.toFixed(2)
        assert.equal 112.5, bb.bottomRight.longitude.toFixed(2)
      'can determine center': (region) ->
        center = region.center
        assert.equal -8.4375, center.latitude.toFixed(4)
        assert.equal 106.875, center.longitude.toFixed(3)

  .export(module)

