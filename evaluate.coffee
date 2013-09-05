EvaluateFromStream = require("./lib/EvaluateFromStream")
TwitterAccess = require('./lib/TwitterAccess')

Graphite = require("./lib/Graphite")
MetricCollector = require("./lib/MetricCollector")

stream = new EvaluateFromStream("http://localhost:5000",TwitterAccess.init())
collector = new MetricCollector(Graphite.initializeInHeroku(), [stream])

stream.start()
collector.collect()
collector.beginPolling(10 * 1000)