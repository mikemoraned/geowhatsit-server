TweetCountsFactory = require("./lib/TweetCountsFactory")
TweetTokenizer = require("./lib/TweetTokenizer")
Stream = require("./lib/Stream")
Graphite = require("./lib/Graphite")
MetricCollector = require("./lib/MetricCollector")
TwitterAccess = require('./lib/TwitterAccess')

tweetCounts = TweetCountsFactory.create(2)

collector = new MetricCollector(Graphite.initializeInHeroku(), [tweetCounts])
collector.collect()
collector.beginPolling(60 * 1000)

stream = new Stream(tweetCounts, TwitterAccess.init(), new TweetTokenizer(2))
stream.start()
