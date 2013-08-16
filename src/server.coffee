###
monitor server
this server will provide a web interface for server data
###

express = require('express')
http = require('http')
port = 3356
Logger = require('./logger')

class Server

  constructor: ->
    @logger = new Logger()

  serv: ->
    @app = express()
    @server = http.createServer(@app)

    @app.configure () =>
      @app.use(@logger.serv)
      @app.use(express.cookieParser())
      @app.use(@app.router)

    @app.get '/', (req, res) ->
      res.send('Welcome to Sneaky!')

    @server.listen(port)
    @logger.log("server listen on #{port}")

  @serv: ->
    server = new Server()
    server.serv()
    return server

module.exports = Server