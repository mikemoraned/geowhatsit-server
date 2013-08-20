express = require("express")
app = express()
app.use(express.logger())

app.get('/', (request, response) ->
  response.send('Hello World!')
)

port = process.env.PORT || 5000
app.listen(port, () ->
  console.log("Listening on " + port)
)

util = require('util')
twitter = require('twitter')

twit = new twitter({
  consumer_key: 'mCp0qZ0zGGcvA9ZKVo7xQ',
  consumer_secret: 'X1Z4FaK8Hv68ZoTUCmiRjDy6IP5d5n7OHYwC6es4A',
  access_token_key: '11510772-MZIWUADlvY7A9Cbz6kKpqbuRM7EfWrdskAnXNpxpE',
  access_token_secret: process.env['TWITTER_ACCESS_TOKEN_SECRET']
})

twit.stream('statuses/sample', (stream) ->
  stream.on('data', (data) ->
    console.log(util.inspect(data))
  )
)