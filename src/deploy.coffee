async = require('async')
readline = require('readline')
fs = require('fs')
jsYaml = require('js-yaml')
Logger = require('./Logger')
exec = require('child_process').exec

localDir = "#{process.env.HOME}/.sneaky"

quit = ->
  setTimeout(process.exit, 200)

main = (options = {}, callback = ->) ->

  # define deploy function for each project
  deploy = (project, callback) ->
    logger.log("start deploy #{project.name}")
    async.waterfall [((next) ->  # begin archive
      prefix = project.prefix or project.name + '/'
      gitCmd = "git archive #{project.version or 'HEAD'} --prefix=#{prefix} " +
        "--remote=#{project.source} --format=tar | tar -xf - -C #{localDir}"
      process.chdir("#{localDir}/#{prefix}")
      runCmd gitCmd, (err, data) ->
        next(err)
      ), ((next) ->
      before(project, next)
      ), ((next) ->
      servers = ssh(project)
      async.eachSeries servers, ((server, _next) ->
        rsyncCmd = project.rsyncCmd or "rsync -a --delete-after --ignore-errors --force " +
          "#{localDir}/#{project.name} #{server[0]}@#{server[1]}:#{project.destination}"
        runCmd rsyncCmd, (err, data) ->  # begin rsync
          _next(err)
        ), (err, result) ->
        next(err)
      )], (err, result) ->
        if err?
          logger.err(err.toString())
        logger.log("finish deploy #{project.name}")
        callback(err, result)
  # define deploy end

  archive = (project) ->

  before = (project, callback = ->) ->
    if project.before? and typeof project.before == 'string'
      runCmd project.before, (err, data) ->
        callback(err)
    else
      callback(null)

  # define ssh user and server
  ssh = (project) ->
    servers = []
    if typeof project.server == 'string'
      [server, user] = project.server.split('|')
      user = user or configs.user or 'root'
      server = server or configs.server
      servers.push([user, server])
    else
      for i, item of project.server
        [server, user] = item.split('|')
        user = user or configs.user or 'root'
        server = server or configs.server
        servers.push([user, server])
    return servers
  # define ssh finish


  # define run command
  runCmd = (cmd, callback = ->) ->
    logger.log(cmd)
    exec cmd, (err, data) ->
      logger.log(data.toString())
      callback(err, data)

  # define run command end

  # define autoTag
  autoTag: ->
  # define autoTag finish

  logger = new Logger()
  logger.setPrefix({
    warn: 'WARN: '
    err: 'ERR: '
    })

  start = new Date()
  logger.log('=================================================================')
  logger.log('start', start.toString())

  # read configs
  configs = (->
    configPath = options.config or '~/.sneakyrc'
    configPath = logger.expandPath(configPath)
    try
      return jsYaml.load(fs.readFileSync(configPath, 'utf-8'))
    catch e
      if e?
        switch e.name
          when 'YAMLException' then logger.err("please check your configure file's format")
          else logger.err("missing sneakyrc file, did you put this file in path #{configPath} ?")
      quit()
    )()
  # read configs end

  # check projects
  until configs.projects? and configs.projects.length > 0
    logger.err('please define the project info in the `projects` collection')
  # check projects end

  # start deploy
  async.eachSeries configs.projects, deploy, (err, result) ->
    if err?
      logger.err(err.toString())
      quit()
    end = new Date()
    logger.log('time cost:', end - start)
    logger.log('finish', end)
    logger.log('=================================================================\n')
    callback(err, result)
  # deploy finish



module.exports = main