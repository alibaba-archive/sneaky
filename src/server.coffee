###
monitor server
this server will provide a web interface for server data
###

express = require('express')
http = require('http')
port = 3356
Logger = require('./logger')
Router = require('./Router')

class Server

  constructor: ->
    @logger = new Logger()

  serv: ->
    @app = express()
    @server = http.createServer(@app)

    @app.configure () =>
      @app.use(express.logger(@logger.serv))
      @app.use(express.cookieParser())
      @app.use(@app.router)
      @app.use(express.favicon("#{__dirname}/../public/favicon.ico"))
      @app.use('/', express.static("#{__dirname}/../public"))
      @app.get '/users/:id', (req, res) ->
        Router.aliasRoute(req, res, {
          ctrl: 'user'
          method: 'index'
          })
      Router.route(@app)
    @server.listen(port)
    @logger.log("server listen on #{port}")

  @serv: ->
    server = new Server()
    server.serv()
    return server

module.exports = Server