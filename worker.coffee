TweetCountsFactory = require("./lib/TweetCountsFactory")
TweetTokenizer = require("./lib/TweetTokenizer")
TweetCountsFromStream = require("./lib/TweetCountsFromStream")
Graphite = require("./lib/Graphite")
MetricCollector = require("./lib/MetricCollector")
TwitterAccess = require('./lib/TwitterAccess')

tweetCounts = TweetCountsFactory.create("prod", 2)

collector = new MetricCollector(Graphite.initializeInHeroku(), [tweetCounts])
collector.collect()
collector.beginPolling(60 * 1000)

stream = new TweetCountsFromStream(tweetCounts, TwitterAccess.init(), new TweetTokenizer(2))
stream.start()
