EvaluateFromStream = require("./lib/EvaluateFromStream")
TwitterAccess = require('./lib/TwitterAccess')

stream = new EvaluateFromStream("http://localhost:5000",TwitterAccess.init())
stream.start()
