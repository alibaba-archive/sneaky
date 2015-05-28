express = require 'express'

app = express()

app.use (req, res) -> res.end('ok')

app.listen 7887
