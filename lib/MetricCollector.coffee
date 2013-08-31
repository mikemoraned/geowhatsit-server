
class MetricCollector
  constructor: (@graphite, @collectables) ->

  beginPolling: (interval) =>
    console.log("Will collect metrics every #{interval} millis")
    setTimeout(@collect, interval)

  collect: =>
    for collectable in @collectables
      collectable.collectMetrics(@graphite)

module.exports = MetricCollector