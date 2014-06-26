fs = require('fs')
path = require('path')
async = require('async')
_ = require('underscore')
logger = require('graceful-logger')
{exec} = require('child_process')

projectPrefix = 'project:'

util =
  sep1: '================================================================='
  sep2: '-----------------------------------------------------------------'
  execCmd: (cmd, callback = ->) ->
    logger.info("run command: #{cmd}")
    child = exec(cmd, callback)
    child.stdout.on 'data', (data) -> process.stdout.write(data)
    child.stderr.on 'data', (data) -> process.stderr.write(data)

  expandPath: (filePath) ->
    return if matches = filePath.match(/^~(.*)/) then "#{process.env.HOME}#{matches[1]}" else filePath

  getConfigPath: (file) ->
    configPath = file
    unless configPath?
      filePaths = [
        path.resolve './.sneakyrc.json'
        path.resolve './.sneakyrc.js'
        path.resolve './.sneakyrc'
        util.expandPath '~/.sneakyrc.json'
        util.expandPath '~/.sneakyrc.js'
        util.expandPath '~/.sneakyrc'
      ]
      for i, file of filePaths
        if fs.existsSync file
          configPath = file
          break
      configPath or= util.expandPath '~/.sneakyrc.json'
    return configPath

  loadConfig: (file, callback = ->) ->
    args = arguments
    async.waterfall [
      (next) ->
        configPath = util.getConfigPath file
        try
          configs = JSON.parse(fs.readFileSync configPath)
        catch e
          configs = {}
        next null, configs
      (configs, next) ->
        for k, config of configs
          config.name or= path.basename(process.cwd()) + "-#{k}"
        next(null, configs)
    ], callback

  saveConfig: (file, configs, callback = ->) ->
    configPath = util.getConfigPath file
    fs.writeFile(configPath, JSON.stringify(configs, null, 2), callback)

module.exports = util
