_ = require('underscore')
{loadConfig, saveConfig} = require('./util')
read = require('read')
logger = require('graceful-logger')
ini = require('ini')
async = require('async')
path = require('path')

class Config

  constructor: (@options) ->
    @configFile = options.configFile

  _readConfigs: (configFile, callback = ->) ->
    loadConfig configFile, (err, configs) =>
      @configs = configs
      callback(err, configs)

  _stepSource: (project, callback = ->) ->
    @_extendDefault('source', project, null, callback)

  _stepVersion: (project, callback = ->) ->
    @_extendDefault('version', project, 'HEAD', callback)

  _stepDest: (project, callback = ->) ->
    @_extendDefault 'destinations', project, null, (err, destinations) ->
      project.destinations = destinations.split(',').map (item) -> item.trim() if destinations?
      callback(err)

  _stepExcludes: (project, callback = ->) ->
    @_extendDefault 'excludes', project, 'node_modules, .git', (err, excludes) ->
      project.excludes = excludes.split(',').map (item) -> item.trim() if excludes?
      callback(err)

  _stepBefore: (project, callback = ->) ->
    @_extendDefault('before', project, null, callback)

  _stepAfter: (project, callback = ->) ->
    @_extendDefault('after', project, null, callback)

  ###
  # @prop property name
  # @project project object
  # @defaultValue default value
  # @isExtend use extension
  # @callback callback
  ###
  _extendDefault: (prop, project, defaultValue = null, callback = ->) ->
    options =
      prompt: "do you want specific #{prop} for #{project.name}?"
    options.default = defaultValue if defaultValue?
    read options, (err, result) ->
      result = result or defaultValue
      project[prop] = result if result?
      callback(err, result)

  _saveTemplate: (project, callback = ->) ->
    projects = @configs.projects
    read
      prompt: 'save this project as template? Y/n'
      default: 'y'
      , (err, result) =>
        if result.toLowerCase() in ['y', 'yes']
          @configs['template'] = _.clone(project)
          saveConfig @configFile, @configs, (err) ->
            if err?
              logger.err(err)
            else
              logger.info('template saved')
            callback(err)

  _saveProject: (project, callback = ->) ->
    console.log project
    @configs[project.name] = project
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
    projects = @configs
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
        delete @configs[projectName]
        saveConfig @configFile, @configs, (err) ->
          if err
            logger.err(err)
          else
            logger.info('project deleted')
          callback(err)

  edit: (callback = ->) ->
    projects = @configs
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
    projects = @configs
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
