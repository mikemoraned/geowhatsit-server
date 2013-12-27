Snapshotter = require('./lib/Snapshotter')
S3 = require('knox')

client = S3.createClient({
  key: process.env['AMAZON_S3_KEY']
  secret: process.env['AMAZON_S3_SECRET']
  bucket: "geowhatsit"
});

snapshotter = new Snapshotter(client)
snapshotter.beginPolling("http://geowhatsit-server.herokuapp.com/regions/", "regions", 1000 * 60)
