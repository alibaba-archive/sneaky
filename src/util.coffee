fs = require('fs')
ini = require('ini')
_ = require('underscore')

class Util

  projectPrefix = 'project:'

  @expandPath: (srcPath) ->
    if matches = srcPath.match(/^~(.*)/)
      return "#{process.env.HOME}#{matches[1]}"
    else
      return srcPath

  @expandToArray: (str) ->
    if typeof str is 'string' and str.length > 0
      return str.split(',').map (r) -> r.trim()
    return []

  @loadConfig: (file, expand = true, callback = ->) ->

    if typeof arguments[1] is 'function'
      callback = arguments[1]
      expand = true

    configFile = Util.expandPath(file or '~/.sneakyrc')
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
              when 'excludes', 'servers'
                _project[kk] = if expand then Util.expandToArray(vv) else vv
          _project.name = k[projectPrefix.length..].trim()
          _configs['projects'][_project.name] = _project
          continue
        switch k
          when 'excludes', 'servers'
            _configs[k] = if expand then Util.expandToArray(v) else v
          else
            _configs[k] = v
      callback(err, _configs)

  @saveConfig: (file, configs, callback = ->) ->
    configFile = Util.expandPath(file or '~/.sneakyrc')
    _configs = {}
    _filterProp = (prop, val) ->
      switch prop
        when 'excludes', 'servers'
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

module.exports = Util
