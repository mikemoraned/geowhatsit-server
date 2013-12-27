URL = require("url")
REQUEST = require("request")

class Snapshotter

  constructor: (@s3) ->

  beginPolling: (url, path, interval) =>
    console.log("Will collect snapshot of #{url} every #{interval} millis")
    job = () => @_snapshot(url, path)
    setInterval(job, interval)
    job()

  _snapshot: (url, destinationPath) =>
    timestamp = Date.now()
    console.log("Snapshotting at #{timestamp}")
    REQUEST(url, (error, response, body) =>
      if !error && response.statusCode == 200
        console.dir(response.headers)
        path = "#{timestamp}/#{destinationPath}"
        s3Request = @s3.put(path, {
          'Content-Length': response.headers['content-length']
          'Content-Type': response.headers['content-type']
          'Date' : response.headers['date']
        })
        s3Request.on('response', (result) =>
          if (result.statusCode == 200)
            console.log('saved to %s', s3Request.url)
          else
            console.log('could not save to %s', s3Request.url)
        )
        s3Request.end(body)
    )

module.exports = Snapshotter