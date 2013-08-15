colors = require('colors')
fs = require('fs')
mkdirp = require('mkdirp')
Moment = require('moment')

class Logger

  constructor: (logFile = null, writeOptions = null, readOptions = null) ->
    moment = new Moment()
    @logPath = "#{process.env.HOME}/.sneaky/logs"
    @logFile = logFile or "#{@logPath}/#{moment.format('YYYY-MM-DD')}.log"
    @writeOptions = writeOptions or {flag: 'a'}
    @readOptions = readOptions or {encoding: 'utf8'}
    @prefix =
      log: 'info'
      err: 'ERR!'
      warn: 'WARN'
    mkdirp.sync(@logPath)

  setPrefix: (prefix) ->
    for type, string of prefix
      @prefix[type] = string

  @expandPath: (uPath) ->
    if matches = uPath.match(/^~(.*)/)  # home path
      return "#{process.env.HOME}#{matches[1]}"
    return uPath

  _log: (str, prefix = '') =>
    console.log("#{prefix}#{str}")
    fs.writeFile(@logFile, "#{str}\n", @writeOptions)

  background: ->
    @log.log("progress is now running in background, you can checkout the log in #{logFile}.mess")
    fs.writeFile(@logFile, "#{(v for i, v of arguments).join(' ')}\n", {flag: 'a'})

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
    fs.readFile(@logFile, @readOptions, callback)

  readFileSync: ->
    return fs.readFileSync(@logFile, @readOptions)

module.exports = Logger