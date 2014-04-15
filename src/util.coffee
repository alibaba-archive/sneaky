fs = require('fs')
path = require('path')
ini = require('ini')
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

  expandPath: (srcPath) ->
    if matches = srcPath.match(/^~(.*)/)
      return "#{process.env.HOME}#{matches[1]}"
    else
      return srcPath

  expandToArray: (str) ->
    if typeof str is 'string' and str.length > 0
      return str.split(',').map (r) -> r.trim()
    return []

  getConfigPath: (file, callback = ->) ->
    if file?
      callback(null, util.expandPath(file))
    else
      configFile = path.join(path.resolve('./.sneakyrc'))
      fs.exists configFile, (exists) =>
        if exists
          return callback(null, configFile)
        else
          return callback(null, util.expandPath('~/.sneakyrc'))

  loadConfig: (file, callback = ->) ->
    args = arguments
    async.waterfall [
      (next) ->
        util.getConfigPath(file, next)
      (file, next) ->
        fs.readFile(file, next)
      (content, next) ->
        try
          configs = JSON.parse(content)
          next(null, configs)
        catch e
          logger.warn """
            #{file} is not a valid json file
            ini-format configure file is deprecated
            and will be removed in the next version.
          """
          util._loadConfigFromIni file, true, (err, configs) ->
            next(err, configs?.projects or {})
      (configs, next) ->
        for k, config of configs
          config.name or= path.basename(process.cwd()) + "-#{k}"
        next(null, configs)
    ], callback

  initojson: (file, callback = ->) ->
    @_loadConfigFromIni file, true, (err, configs) ->
      configs = configs.projects
      for k, config of configs
        delete config.name if config.name
      fs.writeFile(file, JSON.stringify(configs, null, 2), callback)

  # Remote this function in version 0.6
  _loadConfigFromIni: (file, expand = true, callback = ->) ->

    if typeof arguments[1] is 'function'
      callback = arguments[1]
      expand = true

    util.getConfigPath file, (err, configFile) =>
      fs.readFile configFile, (err, content) =>
        return callback(err, content) if err?
        configs = ini.parse(content.toString())
        _configs = {}
        for k, v of configs
          if k.indexOf(projectPrefix) is 0
            _configs.projects = {} unless _configs.projects?
            _project = v
            for kk, vv of _project
              switch kk
                when 'excludes', 'servers', 'destinations', 'ports'
                  _project[kk] = if expand then util.expandToArray(vv) else vv
            _project.name = k[projectPrefix.length..].trim()
            _configs['projects'][_project.name] = _project
            continue
          switch k
            when 'excludes', 'servers'
              _configs[k] = if expand then util.expandToArray(v) else v
            else
              _configs[k] = v
        callback(err, _configs)

  saveConfig: (file, configs, callback = ->) ->
    util.getConfigPath file, (err, configFile) =>
      _configs = {}

      _filterProp = (prop, val) ->
        switch prop
          when 'excludes', 'servers', 'destinations', 'ports'
            return val.join(',')
          else
            return val

      for k, v of configs
        if k is 'projects'
          if v.template?
            _configs["#{projectPrefix} template"] = v.template
            delete v.template
          for kk, project of v
            _configs["#{projectPrefix} #{project.name}"] = project
        else
          _configs[k] = v

      fs.writeFile(configFile, ini.stringify(_configs), callback)

module.exports = util
