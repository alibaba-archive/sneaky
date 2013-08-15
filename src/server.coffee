###
monitor server
this server will provide a web interface for server data
###

http = require('http')
port = 3356
Logger = require('./logger')
CpuMonitor = require('./monitors/cpu')

class Server

  constructor: ->
    @logger = new Logger()

  serv: ->
    @server = http.createServer (req, res) =>
    @server.listen(port)
    @logger.log("server listen on #{port}")
    cpuMonitor = new CpuMonitor
    cpuMonitor.monitor()

  @serv: ->
    server = new Server()
    server.serv()
    return server

module.exports = Server