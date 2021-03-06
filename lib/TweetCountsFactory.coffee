redis = require('redis')
url = require('url')
RedisTweetCounts = require('./RedisTweetCounts')

class TweetCountsFactory
  @create: (name, precision) ->
    if process.env.REDISCLOUD_URL?
      console.log("Using RedisCloud Redis")
      redisURL = url.parse(process.env.REDISCLOUD_URL)
      client = redis.createClient(redisURL.port, redisURL.hostname, {no_ready_check: true})
      client.auth(redisURL.auth.split(":")[1])
    else
      console.log("Using Local Redis")
      client = redis.createClient()

    new RedisTweetCounts(client, precision, name)

module.exports = TweetCountsFactory