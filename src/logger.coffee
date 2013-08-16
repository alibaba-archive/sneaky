colors = require('colors')
fs = require('fs')
mkdirp = require('mkdirp')
Moment = require('moment')
_ = require('underscore')

class Logger

  constructor: (fileName, options = {}) ->
    moment = new Moment()
    @logPath = "#{process.env.HOME}/.sneaky/logs"
    @logFile = if fileName? then "#{@logPath}/#{moment.format('YYYY-MM-DD')}.#{fileName}.log" else
      "#{@logPath}/#{moment.format('YYYY-MM-DD')}.log"
    @prefix =
      log: 'info'
      err: 'ERR!'
      warn: 'WARN'
    @options = options
    @options.write = @options.write or {flag: 'a'}
    @options.read = @options.read or {encoding: 'utf8'}
    @instanceOptions = _.clone(@options)
    mkdirp.sync(@logPath)

  setPrefix: (prefix) ->
    for type, string of prefix
      @prefix[type] = string
    return this

  setOptions: (options) ->
    if options['background'] then @log("progress is now running in background, you can checkout the log in #{@logFile}")
    @options = _.extend(@options, options)
    return this

  resetOptions: ->
    @options = _.clone(@instanceOptions)
    return this

  @expandPath: (uPath) ->
    if matches = uPath.match(/^~(.*)/)  # home path
      return "#{process.env.HOME}#{matches[1]}"
    return uPath

  _log: (str, prefix = '') =>
    return @background(str) if @options['background']
    console.log("#{prefix}#{str}") unless @options['quiet']
    fs.writeFile(@logFile, "#{str}\n", @options.write)
    return this

  background: ->
    fs.writeFile(@logFile, "#{(v for i, v of arguments).join(' ')}\n", {flag: 'a'})
    return this

  log: ->
    prefix = if @prefix['log'].length > 0 then "#{@prefix['log'].green}: " else ''
    @_log.apply(this, ["#{(v for i, v of arguments).join(' ')}", prefix])

  warn: ->
    prefix = if @prefix['warn'].length > 0 then "#{@prefix['warn'].yellow}: " else ''
    @_log.apply(this, ["#{(v for i, v of arguments).join(' ')}", prefix])

  err: ->
    prefix = if @prefix['err'].length > 0 then "#{@prefix['err'].red}: " else ''
    @_log.apply(this, ["#{(v for i, v of arguments).join(' ')}", prefix])

  readFile: (callback = ->) ->
    fs.readFile(@logFile, @options.read, callback)

  readFileSync: ->
    try
      return fs.readFileSync(@logFile, @options.read)
    catch e
      @err(e.toString())
      return null

  serv: (req, res, next) =>
    moment = new Moment()
    console.log req
    @log("#{req.method} #{req.url} #{res.statusCode} #{moment.format('YYYY-MM-DD HH:mm:ss')}")
    next()

module.exports = Logger