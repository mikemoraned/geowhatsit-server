twitter = require('twitter')

class TwitterAccess
  @init: () ->
    new twitter({
      consumer_key: 'mCp0qZ0zGGcvA9ZKVo7xQ',
      consumer_secret: 'X1Z4FaK8Hv68ZoTUCmiRjDy6IP5d5n7OHYwC6es4A',
      access_token_key: '11510772-MZIWUADlvY7A9Cbz6kKpqbuRM7EfWrdskAnXNpxpE',
      access_token_secret: process.env['TWITTER_ACCESS_TOKEN_SECRET']
    })

module.exports = TwitterAccess