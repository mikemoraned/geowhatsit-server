URL = require("url")

class Snapshotter

  constructor: (@s3) ->

  beginPolling: (url, path, interval) =>
    console.log("Will collect snapshot of #{url} every #{interval} millis")
    setInterval(
      () => @_snapshot(url, path)
      ,
      interval)

  _snapshot: (URL, destination) =>
    timestamp = Date.now()
    console.log("Snapshotting at #{timestamp}")

module.exports = Snapshotter