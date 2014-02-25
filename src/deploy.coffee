async = require('async')
path = require('path')
fs = require('graceful-fs')
_ = require('underscore')
Moment = require('moment')
mkdirp = require('mkdirp')
logger = require('graceful-logger')
{exec} = require('child_process')
{expandPath, loadConfig} = require('./util')

sep1 = '================================================================='

sep2 = '-----------------------------------------------------------------'

# define exec command
execCmd = (cmd, callback = ->) ->
  logger.info("Run command: [#{cmd}]")
  child = exec(cmd, callback)
  child.stdout.on 'data', (data) -> logger.info(data.toString().trim())
  child.stderr.on 'data', (data) -> logger.err(data.toString().trim())
# finish define exec command

class Deploy

  constructor: (options) ->
    @options = _.extend({
      chdir: "#{process.env.HOME}/.sneaky"
      force: true
      config: "#{process.env.HOME}/.sneakyrc"
    }, options)
    @options.config or= path.join(path.resolve('./.sneakyrc'))

  getServers: (project) =>
    servers = []
    if typeof project.servers is 'object'
      for i, item of project.servers
        [server, user, port] = item.split('|')
        user = user or project.user or @configs.user or 'root' # ssh user name
        port = port or '22' # ssh port
        servers.push([server, user, port])
    else if @configs.servers?
      return @getServers(@configs)
    return servers

  readRecords: ->
    moment = new Moment
    recordDir = path.join(@options.chdir, "_records")
    try
      @records = require(path.join(recordDir, "#{moment.format('YYYYMMDD')}.json"))
    catch e
      @records = {}
    return @records

  writeRecords: (callback = ->) ->
    recordDir = path.join(@options.chdir, "_records")
    mkdirp recordDir, (err, parent) =>
      logger.err("Cound not mkdir #{recordDir}", 1) if err?
      moment = new Moment
      fs.writeFile path.join(recordDir, "#{moment.format('YYYYMMDD')}.json"),
        JSON.stringify(@records, null, 2), (err, result) ->
          logger.err("Cound not write record file", 1) if err?
          return callback(err, result)

  run: (callback = ->) ->
    loadConfig @options.config, (err, configs) =>
      return callback("Missing config file") unless configs?
      if _.isEmpty(configs.projects)
        logger.err('please define the project info in the `projects` collection', 1)
      @configs = configs
      start = new Date()
      logger.info(sep1)
      logger.info('Job start at', start)
      records = @readRecords()
      runProjects = []
      allProjects = configs.projects
      if @options.projects?.length > 0  # Choose specific projects
        @options.projects.forEach (projectName) ->
          if allProjects[projectName]?
            runProjects.push(allProjects[projectName])
          else
            logger.warn("Can not find project [#{projectName}]")
      else
        runProjects = (v for k, v of configs.projects)
      async.eachSeries runProjects, @deploy, (err, result) ->
        if err?
          logger.err(err.toString())
          logger.err('Deploy Failed!', 1)
        else
          end = new Date()
          logger.info('Time cost:', (end - start) / 1000, " Seconds")
          logger.info('Deploy finished at', end)
          logger.info('Please checkout your remote directory')
        logger.info(sep1)
        callback(err, result)

  deploy: (project, callback = ->) =>
    return callback(null) if project.name is 'template'
    logger.info(sep2)
    logger.info("Start deploy [#{project.name}]")
    if @records[project.name] in ['success', 'processing'] and not @options.force
      logger.warn("Project [#{project.name}] has been deployed, skipping...")
      logger.info(sep2)
      return callback(null)
    @records[project.name] = 'processing'
    @writeRecords()
    async.waterfall [((next) =>
        @autoTag(project, next)
      )
      , @archive
      , @before
      , @rsync
      , @after
      ], (err, result) =>
        if err?
          logger.err(err)
          @records[project.name] = 'fail'
        else
          @records[project.name] = 'success'
          logger.info("Finish deploy [#{project.name}]")
        @writeRecords()
        logger.info(sep2)
        callback(err, project)

  autoTag: (project, callback = ->) =>
    return callback(null, project) unless project.autoTag
    return callback("#{project.source} is not a local repository, " +
      "you could not use `autoTag` for a remote repository.") unless project.source.match(/^[a-zA-Z._\/\~\-]+$/)
    process.chdir(expandPath(project.source))
    execCmd 'git tag', (err, data) =>
      return callback(err) if err?
      moment = new Moment()
      newTag = "#{project.tagPrefix or 'release'}-#{moment.format('YYYY.MM.DD.HHmmss')}"
      tagCmd = "git tag #{newTag} -m 'auto generated tag #{newTag} by sneaky " +
        "at #{moment.format('YYYY-MM-DD HH:mm:ss')}'"
      execCmd tagCmd, (err, data) ->
        project.version = newTag
        callback(err, project)

  archive: (project, callback = ->) =>
    prefix = project.prefix or project.name + '/'
    return callback('missing project source directory') unless project.source?
    gitCmd = "rm -rf #{path.join(@options.chdir, prefix)}; " +
      "git archive #{project.version or 'HEAD'} --prefix=#{prefix} " +
      "--remote=#{project.source} --format=tar | tar -xf - -C #{@options.chdir}"
    execCmd gitCmd, (err, data) =>
      callback(err, project)

  rsync: (project, callback = ->) =>
    if project.local
      @_localRsync(project, callback)
    else
      @_sshRsync(project, callback)

  _sshRsync: (project, callback = ->) ->
    servers = @getServers(project)
    excludes = []
    if typeof project.excludes is 'object' and project.excludes.length > 0
      excludes = project.excludes.map (item) -> "--exclude=#{item}"
    async.eachSeries servers, ((server, next) =>
      rsyncCmd = project.rsyncCmd or "rsync -a --timeout=15 --delete-after --ignore-errors --force" +
        " -e \"ssh -p #{server[2]}\" " +
        excludes.join(' ') +
        " #{@options.chdir}/#{project.name}/ #{server[1]}@#{server[0]}:#{project.destination}"
      execCmd rsyncCmd, (err, data) ->
        next(err)
      ), (err, result) ->
      callback(err, project)

  _localRsync: (project, callback = ->) ->
    if typeof project.excludes is 'object' and project.excludes.length > 0
      excludes = project.excludes.map (item) -> "--exclude=#{item}"
      rsyncCmd = project.rsyncCmd or "rsync -a --timeout=15 --delete-after --ignore-errors --force" +
        " " + excludes.join(' ') +
        " #{@options.chdir}/#{project.name}/ #{project.destination}"
      execCmd rsyncCmd, (err, data) ->
        callback(err, project)

  before: (project, callback = ->) =>
    if project.before? and typeof project.before is 'string'
      logger.info('Before hook:', project.before)
      prefix = project.prefix or project.name + '/'
      process.chdir("#{@options.chdir}/#{prefix}")
      execCmd project.before, (err, data) ->
        callback(err, project)
    else
      callback(null, project)

  after: (project, callback = ->) =>
    servers = @getServers(project)
    prefix = project.prefix or project.name + '/'
    if project.after? and typeof project.after is 'string'
      logger.info('After hook:')
      if project.local
        logger.info project.after
        execCmd project.after, (err, data) ->
          callback(err, project)
      else
        async.eachSeries servers, ((server, next) ->
          sshCmd = "ssh -t -t #{server[1]}@#{server[0]} -p #{server[2]} \"#{project.after}\""
          logger.info(sshCmd)
          execCmd sshCmd, (err, data) ->
            next(err)
          ), (err, result) ->
          callback(err, project)
    else
      callback(null, project)

deploy = (options) ->
  $deploy = new Deploy(options)
  $deploy.run()

deploy.Deploy = Deploy

module.exports = deploy
