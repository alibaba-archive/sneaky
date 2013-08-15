async = require('async')
fs = require('fs')
jsYaml = require('js-yaml')
Logger = require('./Logger')
{exec} = require('child_process')
Moment = require('moment')

local =
  dir: "#{process.env.HOME}/.sneaky"  # local home directory
  configs: {}  # configs from ~/.sneakyrc
  logger: null  # pre define logger
  force: false  # choose force deploy or false
  records: {}  # default recodes
  recordLogger: null  # action data recorder

quit = ->
  setTimeout(process.exit, 200)

# deploy function for each project
deploy = (project, callback) ->
  local.logger.log('-----------------------------------------------------------------')
  local.logger.log("start deploy #{project.name}")
  if local.records[project.name] in ['success', 'processing'] and not local.force  # could not deploy
    local.logger.warn("#{project.name} has been deployed, skipping")
    local.logger.log('-----------------------------------------------------------------')
    return callback(null)
  local.records[project.name] = 'processing'
  local.recordLogger.log(JSON.stringify(local.records))
  async.waterfall [((next) ->
    if project.autoTag
      autoTag project, (err, tag) ->
        project.version = tag unless err?
        next(err)
    else
      next()
    ), ((next) ->  # begin archive
    archive(project, next)
    ), ((next) ->
    before(project, next)
    ), ((next) ->
    rsync(project, next)
    ), ((next) ->
    after(project, next)
    )], (err, result) ->
      if err?
        local.logger.err(err.toString())
        local.records[project.name] = 'fail'
      else
        local.records[project.name] = 'success'
        local.logger.log("finish deploy #{project.name}")
      local.recordLogger.log(JSON.stringify(local.records))
      local.logger.log('-----------------------------------------------------------------')
      callback(err, result)
# finish define deploy

# archive from git and migrate to temporary directory
archive = (project, callback = ->) ->
  prefix = project.prefix or project.name + '/'
  gitCmd = "git archive #{project.version or 'HEAD'} --prefix=#{prefix} " +
    "--remote=#{project.source} --format=tar | tar -xf - -C #{local.dir}"
  process.chdir("#{local.dir}/#{prefix}")
  runCmd gitCmd, (err, data) ->
    callback(err)
# finish define archive

# use rsync to deploy local source code to remote servers
rsync = (project, callback = ->) ->
  servers = getServers(project)
  excludes = []
  if typeof project.excludes == 'object' and project.excludes.length > 0
    excludes = project.excludes.map (item) ->
      return "--exclude=#{item}"
  async.eachSeries servers, ((server, next) ->
    rsyncCmd = project.rsyncCmd or "rsync -a --timeout=15 --delete-after --ignore-errors --force" +
      " -e \"ssh -p #{server[2]}\" " +
      excludes.join(' ') +
      " #{local.dir}/#{project.name} #{server[1]}@#{server[0]}:#{project.destination}"
    runCmd rsyncCmd, (err, data) ->
      next(err)
    ), (err, result) ->
    callback(err)
# finish define rsync

# hooks before rsync deploy
before = (project, callback = ->) ->
  if project.before? and typeof project.before == 'string'
    local.logger.log('before-hook:')
    runCmd project.before, (err, data) ->
      callback(err)
  else
    callback(null)
# finish define before hooks

# hooks after rsync deploy
after = (project, callback = ->) ->
  servers = getServers(project)
  if project.after? and typeof project.after == 'string'
    local.logger.log('after-hook:')
    async.eachSeries servers, ((server, next) ->
      sshCmd = "ssh #{server[1]}@#{server[0]} -p #{server[2]} \"#{project.after}\""
      runCmd sshCmd, (err, data) ->
        next(err)
      ), (err, result) ->
      callback(err)
  else
    callback(null)
# finish define after hooks

# get remote user and server
getServers = (project) ->
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
  else if local.configs.servers?
    return getServers(local.configs)
  return servers
# finish define getServers

# define run command
runCmd = (cmd, options, callback = ->) ->
  local.logger.log(cmd) unless options.quiet
  callback = (options or ->) if arguments.length < 3
  exec cmd, (err, data) ->
    local.logger.log(data.toString()) unless options.quiet
    callback(err, data)
# finish define run command

# auto generate tag from git repos
autoTag = (project, callback = ->) ->
  return callback("#{project.source} is not a local repos, " +
    "you could not use `autoTag` for a remote repos.") unless project.source.match(/^[a-zA-Z._\/\~\-]+$/)
  process.chdir(Logger.expandPath(project.source))
  runCmd 'git tag', {quiet: true}, (err, data) ->
    return callback(err) if err?
    moment = new Moment()
    newTag = "#{project.tagPrefix or 'release'}-#{moment.format('YYYY.MM.DD.HHmmss')}"
    tagCmd = "git tag #{newTag} -m 'auto generated tag #{newTag} by sneaky at #{moment.format('YYYY-MM-DD HH:mm:ss')}'"
    runCmd tagCmd, (err, data) ->
      callback(err, newTag)

# finish autoTag

main = (options = {}, callback = ->) ->

  # start from here
  moment = new Moment()
  local.logger = new Logger()
  local.recordLogger = new Logger("#{process.env.HOME}/.sneaky/logs/#{moment.format('YYYY-MM-DD')}.action.log", {flag: 'w'})

  start = new Date()
  local.logger.log('=================================================================')
  local.logger.log('start', start.toString())

  # read configs
  local.configs = (->
    configPath = options.config or '~/.sneakyrc'
    configPath = Logger.expandPath(configPath)
    try
      return jsYaml.load(fs.readFileSync(configPath, 'utf-8'))
    catch e
      if e?
        switch e.name
          when 'YAMLException' then local.logger.err("please check your configure file's format")
          else local.logger.err("missing sneakyrc file, did you put this file in path #{configPath} ?")
      quit()
    )()
  # read configs end

  # check projects
  unless local.configs.projects? and local.configs.projects.length > 0
    local.logger.err('please define the project info in the `projects` collection')
  # check projects end

  # start deploy
  local.recordLogger.readFile (err, data) ->
    try
      local.records = JSON.parse(data) if data?
    catch e
      local.records = {}
    local.force = options.force or false
    async.eachSeries local.configs.projects, deploy, (err, result) ->
      if err?
        local.logger.err(err.toString())
        quit()
      end = new Date()
      local.logger.log('time cost:', end - start)
      local.logger.log('finish', end)
      local.logger.log('=================================================================\n')
      callback(err, result)
  # deploy finish

module.exports = main