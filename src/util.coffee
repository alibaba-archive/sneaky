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

  parseConfig: (configs) ->
    for name, config of configs
      for key, val of config
        # Change array like options to array
        if key in ['destinations', 'excludes', 'includes', 'only'] and
           toString.call(val) is '[object String]'
          configs[name][key] = val.split ' '
        # Expand destinations to meanful properties
        if key is 'destinations'
          for i, dest of configs[name][key]
            continue unless toString.call(dest) is '[object String]'
            _dest = {}
            if dest.indexOf('@') is -1  # local server
              _dest.destination = dest
            else
              [_dest.user, _dest.host, _dest.destination] = dest.split /[@:]/
            configs[name][key][i] = _dest
    return configs

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
    return path.resolve(configPath)

  loadConfig: (file, callback = ->) ->
    args = arguments
    async.waterfall [
      (next) ->
        configPath = util.getConfigPath file
        try
          if path.extname(configPath) in ['.json', '.js']
            configs = require configPath
          else
            configs = JSON.parse(fs.readFileSync configPath)
        catch e
          configs = {}
        next null, configs
      (configs, next) ->
        for k, config of configs
          config.name or= path.basename(process.cwd()) + "-#{k}"
        next(null, configs)
      (configs, next) ->
        next null, util.parseConfig(configs)
    ], callback

  saveConfig: (file, configs, callback = ->) ->
    configPath = util.getConfigPath file
    fs.writeFile(configPath, JSON.stringify(configs, null, 2), callback)

module.exports = util
