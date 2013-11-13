_ = require('underscore')
{loadConfig, saveConfig} = require('./util')
read = require('read')
logger = require('graceful-logger')
ini = require('ini')
async = require('async')
path = require('path')

class Config

  constructor: (@options) ->
    @configFile = options.configFile or "#{process.env.HOME}/.sneakyrc"

  _readConfigs: (configFile, callback = ->) ->
    loadConfig configFile, false, (err, configs) =>
      @configs = configs
      callback(err, configs)

  _stepUser: (project, callback = ->) ->
    _addUser = =>
      options =
        prompt: "do you want a specific user for #{project.name}?"
      user = project.user or @configs.user
      options.default = user if user?
      read options, (err, user) ->
        project.user = user if user? and user.length > 3
        callback(err)

    if @configs.user?
      _addUser()
    else
      read
        prompt: 'do you want to add a global user?'
        , (err, user) =>
          if user? and user.length > 3
            @configs.user = user
            project.user = user
            callback(err)
          else
            logger.warn('ignore global user')
            _addUser()

  _stepServers: (project, callback = ->) ->
    _addServer = =>
      options =
        prompt: "do you want specific servers for #{project.name}?"
      defaultServers = project.servers or @configs.servers
      options.default = defaultServers if defaultServers?
      read options, (err, servers) ->
        servers = servers or defaultServers
        project.servers = servers if servers?
        callback(err)

    if @configs.servers?
      _addServer()
    else
      read
        prompt: 'do you want to add global servers?'
        , (err, servers) =>
          if servers?
            @configs.servers = servers
            project.servers = servers
            callback(err)
          else
            logger.warn('ignore global servers')
            _addServer()

  _stepSource: (project, callback = ->) ->
    @_extendDefault('source', project, null, false, callback)

  _stepVersion: (project, callback = ->) ->
    @_extendDefault('version', project, 'HEAD', false, callback)

  _stepDest: (project, callback = ->) ->
    destination = project['destination'] or null
    unless destination?
      projects = @configs.projects
      if projects?
        for k, _project of projects
          if _project['destination']?
            destination = path.join(path.dirname(_project['destination']), project.name)
            break
    options =
      prompt: "do you want specific destination for #{project.name}?"
    options.default = destination if destination?
    read options, (err, destination) ->
      project.destination = destination if destination?
      callback(err)

  _stepExcludes: (project, callback = ->) ->
    @_extendDefault('excludes', project, 'node_modules, .git', true, callback)

  _stepBefore: (project, callback = ->) ->
    @_extendDefault('before', project, null, false, callback)

  _stepAfter: (project, callback = ->) ->
    @_extendDefault('after', project, null, false, callback)

  ###
  # @prop property name
  # @project project object
  # @defaultValue default value
  # @isExtend use extension
  # @callback callback
  ###
  _extendDefault: (prop, project, defaultValue = null, isExtend = true, callback = ->) ->
    exDefault = project[prop] or null
    unless exDefault? or not isExtend
      projects = @configs.projects
      if projects?
        for k, _project of projects
          if _project[prop]?
            exDefault = _project[prop]
            break
    unless exDefault?
      exDefault = defaultValue
    options =
      prompt: "do you want specific #{prop} for #{project.name}?"
    options.default = exDefault if exDefault?
    read options, (err, result) ->
      result = result or exDefault
      project[prop] = result if result?
      callback(err)

  _saveTemplate: (project, callback = ->) ->
    projects = @configs.projects
    read
      prompt: 'save this project as template? Y/n'
      default: 'y'
      , (err, result) =>
        if result.toLowerCase() in ['y', 'yes']
          template = _.clone(project)
          template.name = 'template'
          @configs.projects['template'] = template
          saveConfig @configFile, @configs, (err) ->
            if err?
              logger.err(err)
            else
              logger.info('template saved')
            callback(err)

  _saveProject: (project, callback = ->) ->
    console.log project
    @configs['projects'][project.name] = project
    read
      prompt: 'look nice? Y/n'
      default: 'y'
      , (err, nice) =>
        if nice.toLowerCase() is 'y' or nice.toLowerCase() is 'yes'
          saveConfig @configFile, @configs, (err) =>
            if err?
              logger.err(err)
              callback(err)
            else
              logger.info('configure saved')
              @_saveTemplate(project, callback)
        else
          callback(err)

  run: ->
    {action} = @options
    @_readConfigs @configFile, (err, configs) =>
      @configs = configs
      if action? and action.indexOf('_') isnt 0 and typeof @[action] is 'function'
        @[action]()
      else
        @interactive()

  show: (callback = ->) ->
    if @configs
      console.log JSON.stringify(@configs, null, 2)
    else
      logger.warn('missing configure file')

  delete: (callback = ->) ->
    {projects} = @configs?
    if _.isEmpty(projects)
      err = 'no projects in configure file'
      logger.err(err)
      return callback(err)
    projectNames = _.keys(projects)
    if 'template' in projectNames
      projectNames.splice(projectNames.indexOf('template'), 1)
    read
      prompt: "which one do you want to delete? #{projectNames.join('/')}"
      , (err, projectName) =>
        unless projectName? and projects[projectName]?
          err = 'please chose a project!'
          logger.err(err)
          return callback(err)
        delete @configs['projects'][projectName]
        saveConfig @configFile, @configs, (err) ->
          if err
            logger.err(err)
          else
            logger.info('project deleted')
          callback(err)

  edit: (callback = ->) ->
    {projects} = @configs?
    if _.isEmpty(projects)
      err = 'no projects in configure file'
      logger.err(err)
      return callback(err)
    projectNames = _.keys(projects)
    if 'template' in projectNames
      projectNames.splice(projectNames.indexOf('template'), 1)
    read
      prompt: "which one do you want to edit? #{projectNames.join('/')}"
      , (err, projectName) =>
        unless projectName? and projects[projectName]?
          err = 'please chose a project!'
          logger.err(err)
          return callback(err)
        project = projects[projectName]
        async.eachSeries [
          '_stepUser'
          '_stepServers'
          '_stepSource'
          '_stepVersion'
          '_stepDest'
          '_stepExcludes'
          '_stepBefore'
          '_stepAfter'
        ], ((func, next) =>
          @[func](project, next)
        ), (err) =>
          if err?
            logger.err(err)
            return callback(err)
          @_saveProject(project, callback)

  add: (callback = ->) ->
    @configs = {} unless @configs
    @configs.projects = {} unless @configs.projects?
    {projects} = @configs
    read
      prompt: 'please enter your project name:'
      , (err, projectName) =>
        if not projectName?
          err = 'missing project name!'
        else if projects[projectName]?
          err = "project #{projectName} is exist!"

        if err?
          logger.err(err)
          return callback(err)

        project =
          name: projectName
        async.eachSeries [
          '_stepUser'
          '_stepServers'
          '_stepSource'
          '_stepVersion'
          '_stepDest'
          '_stepExcludes'
          '_stepBefore'
          '_stepAfter'
        ], ((func, next) =>
          @[func](project, next)
        ), (err) =>
          if err?
            logger.err(err)
            return callback(err)
          @_saveProject(project, callback)


  interactive: (callback = ->) ->
    actionAlias =
      's': 'show'
      'e': 'edit'
      'a': 'add'
      'd': 'delete'
    _interactive = =>
      read
        prompt: "which action do you need? Show/edit/add/delete"
        default: 'show'
        , (err, action, isDefault) =>
          action = action.toLowerCase()
          action = actionAlias[action] if actionAlias[action]?
          if typeof @[action] is 'function' and action.indexOf('_') isnt 0
            @[action] (err) ->
              return callback() unless err?
              read
                prompt: "ouch! something bad happened, do you want to continue? y/N"
                default: 'n'
                , (err, chose) ->
                  if chose.toLowerCase() is 'y'
                    _interactive()
                  else
                    callback(err)
          else
            logger.err("can not find action [#{action}]")

    _interactive()

config = (options) ->
  $config = new Config(options)
  $config.run()

module.exports = config
