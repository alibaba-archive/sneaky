async = require('async')
fs = require('graceful-fs')
_ = require('underscore')
mkdirp = require('mkdirp')
logger = require('graceful-logger')
{loadConfig, sep1, sep2} = require('./util')
steps = require('./steps')

deploy = (options) ->
  _options = _.extend({
    chdir: "#{process.env.HOME}/.sneaky"
    force: true
    config: "#{process.env.HOME}/.sneakyrc"
  }, options)

  start = new Date
  logger.info("job start at #{start}")

  async.waterfall [

    (next) ->
      fs.exists _options.chdir, (exists) ->
        if exists then next() else
          mkdirp _options.chdir, (err) ->
            next(err)

    (next) -> loadConfig(_options.config, next)

    (config, next) ->
      return next(new Error("missing config file")) unless config?
      if _.isEmpty(config.projects)
        return next(new Error("no projects found in the configuration file"))
      allProjects = config.projects
      runProjects = []
      if _options.projects?.length > 0
        for i, name of _options.projects
          if allProjects[name]?
            runProjects.push(allProjects[name])
          else
            return next(new Error("can not find project: #{name}"))
      else
        runProjects = (v for k, v of config.projects when k isnt 'template')
      next(null, runProjects)

    (projects, next) ->

      async.eachSeries projects, (project, _next) ->
        logger.info(sep2)
        logger.info("start deploy: #{project.name}")
        async.eachSeries steps, (step, __next) ->
          step(project, _options, __next)
        , _next
      , next

  ], (err) ->
    logger.info(sep1)
    if err?
      logger.err("#{err}")
      logger.err('deploy failed!')
    else
      end = new Date
      logger.info('time cost:', (end - start) / 1000, " seconds")
      logger.info('deploy finished at', end)
      logger.info('please checkout your remote directory')

module.exports = deploy
