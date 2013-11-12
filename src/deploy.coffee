async = require('async')
path = require('path')
fs = require('graceful-fs')
jsYaml = require('js-yaml')
_ = require('underscore')
logger = require('graceful-logger')
{exec} = require('child_process')
{spawn} = require('child_process')
Moment = require('moment')
mkdirp = require('mkdirp')

sep1 = '================================================================='

sep2 = '-----------------------------------------------------------------'

expandPath = (srcPath) ->
  if matches = srcPath.match(/^~(.*)/)
    return "#{process.env.HOME}#{matches[1]}"
  else
    return srcPath

# define exec command
execCmd = (cmd, callback = ->) ->
  logger.info("Run command: [#{cmd}]")
  exec cmd, (err, data) ->
    logger.info(data.toString())
    callback(err, data)
# finish define exec command

# define spawn command
spawnCmd = (cmd, options, callback = ->) ->
  if arguments.length < 3
    callback = options or ->
  isQuiet = options.quiet or false

  stdout = ''
  stderr = ''
  job = spawn('bash', ['-c', cmd])

  job.stdout.setEncoding('utf-8')
  job.stdout.on 'data', (data) ->
    data = data.trim()
    stdout += data
    logger.info(data)

  job.stderr.setEncoding('utf-8')
  job.stderr.on 'data', (data) ->
    data = data.trim()
    stderr += data
    logger.warn(data)

  job.on 'close', (code) ->
    return callback(stderr) if code != 0
    callback(code, stdout)
# finish define spawn command

class Deploy

  constructor: (options) ->
    @options = _.extend({
      chdir: "#{process.env.HOME}/.sneaky"
      force: false
    }, options)

  loadConfigs: ->
    configFile = expandPath(@options.config or '~/.sneakyrc')
    try
      @configs = jsYaml.load(fs.readFileSync(configFile, 'utf-8'))
    catch err
      switch err?.name
        when 'YAMLException' then logger.err("please check your configure file's format")
        else logger.err("missing sneakyrc file, did you put this file in path #{configFile} ?")
    unless @configs.projects? and @configs.projects.length > 0
      logger.err('please define the project info in the `projects` collection')
    return @configs

  getServers: (project) =>
    servers = []
    if typeof project.servers == 'string'
      [server, user, port] = project.servers.split('|')
      user = user or local.configs.user or 'root'  # ssh user name
      port = port or '22'  # ssh port
      servers.push([server, user, port])
    else if typeof project.servers == 'object'
      for i, item of project.servers
        [server, user, port] = item.split('|')
        user = user or local.configs.user or 'root'  # ssh user name
        port = port or '22'  # ssh port
        servers.push([server, user, port])
    else if @configs.servers?
      return @getServers(@configs)
    return servers

  readActionRecord: ->
    moment = new Moment
    try
      actionRecord = fs.readFileSync(path.join(@options.chdir, "var/actions/#{moment.format('YYYY-MM-DD')}.txt"))
      @records = JSON.parse(actionRecord)
    catch e
      @records = {}

  writeActionRecord: (callback = ->) ->
    actionDir = path.join(@options.chdir, "var/actions")
    mkdirp actionDir, (err, parent) =>
      if err?
        logger.err("Cound not mkdir #{actionDir}")
        return callback(err, parent)
      else
        moment = new Moment
        fs.writeFile path.join(actionDir, "#{moment.format('YYYY-MM-DD')}.txt"),
          JSON.stringify(@records, null, 2), (err, result) ->
            logger.err("Cound not write record file") if err?
            return callback(err, result)

  run: (callback = ->) ->
    configs = @loadConfigs()
    return callback("Missing config file") unless configs?
    start = new Date()
    logger.info(sep1)
    logger.info('Job start at', start)
    records = @readActionRecord()
    projects = []
    allProjects = {}
    allProjects[project.name] = project for i, project of @configs.projects
    if @options.projects?  # Choose specific projects
      projectNames = @options.projects.split(',')
      projectNames.forEach (projectName) ->
        if allProjects[projectName]?
          projects.push(allProjects[projectName])
        else
          logger.warn("Can not find project [#{projectName}]")
    else
      projects = @configs.projects
    async.eachSeries projects, @deploy, (err, result) ->
      if err?
        logger.err(err.toString())
        logger.err('Deploy Failed!')
      else
        end = new Date()
        logger.info('Time cost:', (end - start) / 1000, " Seconds")
        logger.info('Deploy finished at', end)
        logger.info('Please checkout your remote directory')
      logger.info(sep1)
      callback(err, result)

  deploy: (project, callback = ->) =>
    logger.info(sep2)
    logger.info("Start deploy [#{project.name}]")
    if @records[project.name] in ['success', 'processing'] and not @options.force
      logger.warn("Project [#{project.name}] has been deployed, skipping...")
      logger.info(sep2)
      return callback(null)
    @records[project.name] = 'processing'
    @writeActionRecord()
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
        @writeActionRecord()
        logger.info(sep2)
        callback(err, project)

  autoTag: (project, callback = ->) =>
    return callback(null, project) unless project.autoTag
    return callback("#{project.source} is not a local repos, " +
      "you could not use `autoTag` for a remote repos.") unless project.source.match(/^[a-zA-Z._\/\~\-]+$/)
    process.chdir(expandPath(project.source))
    execCmd 'git tag', (err, data) =>
      return callback(err) if err?
      moment = new Moment()
      newTag = "#{project.tagPrefix or 'release'}-#{moment.format('YYYY.MM.DD.HHmmss')}"
      tagCmd = "git tag #{newTag} -m 'auto generated tag #{newTag} by sneaky at #{moment.format('YYYY-MM-DD HH:mm:ss')}'"
      execCmd tagCmd, (err, data) ->
        project.version = newTag
        callback(err, project)

  archive: (project, callback = ->) =>
    prefix = project.prefix or project.name + '/'
    gitCmd = "rm -rf #{path.join(@options.chdir, prefix)}; git archive #{project.version or 'HEAD'} --prefix=#{prefix} " +
      "--remote=#{project.source} --format=tar | tar -xf - -C #{@options.chdir}"
    execCmd gitCmd, (err, data) =>
      process.chdir("#{@options.chdir}/#{prefix}")
      callback(err, project)

  rsync: (project, callback = ->) =>
    servers = @getServers(project)
    excludes = []
    if typeof project.excludes == 'object' and project.excludes.length > 0
      excludes = project.excludes.map (item) =>
        return "--exclude=#{item}"
    async.eachSeries servers, ((server, next) =>
      rsyncCmd = project.rsyncCmd or "rsync -a --timeout=15 --delete-after --ignore-errors --force" +
        " -e \"ssh -p #{server[2]}\" " +
        excludes.join(' ') +
        " #{@options.chdir}/#{project.name}/ #{server[1]}@#{server[0]}:#{project.destination}"
      execCmd rsyncCmd, (err, data) ->
        next(err)
      ), (err, result) ->
      callback(err, project)

  before: (project, callback = ->) =>
    if project.before? and typeof project.before == 'string'
      logger.info('Before hook:', project.before)
      spawnCmd project.before, (err, data) ->
        callback(err, project)
    else
      callback(null, project)

  after: (project, callback = ->) =>
    servers = @getServers(project)
    prefix = project.prefix or project.name + '/'
    if project.after? and typeof project.after == 'string'
      logger.info('After hook:')
      async.eachSeries servers, ((server, next) ->
        sshCmd = "ssh -t -t #{server[1]}@#{server[0]} -p #{server[2]} \"#{project.after}\""
        logger.info(sshCmd)
        spawnCmd sshCmd, (err, data) ->
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
