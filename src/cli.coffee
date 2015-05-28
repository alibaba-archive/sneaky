require 'coffee-script/register'
path = require 'path'
commander = require 'commander'
Promise = require 'bluebird'
fs = require 'fs'
logger = require 'graceful-logger'
chalk = require 'chalk'

pkg = require '../package'
sneaky = require './sneaky'

[
  'Skyfile'
  'skyfile'
  'skyfile.js'
  'Skyfile.js'
  'skyfile.coffee'
  'Skyfile.coffee'
].some (fileName) ->
  filePath = path.join process.cwd(), fileName
  try
    require filePath if fs.existsSync filePath
  catch err
    logger.warn err.message
    process.exit 1

_deployAction = (taskName) ->
  Promise.resolve()
  .then -> sneaky.getTask taskName
  .then (task) ->
    task.stdout.pipe process.stdout
    task.stderr.pipe process.stderr
    task.deploy()
  .catch (err) -> logger.warn err.message

_historyAction = (taskName) ->
  Promise.resolve()
  .then -> sneaky.getTask taskName
  .then (task) ->
    task.stdout.pipe process.stdout
    task.stderr.pipe process.stderr
    task.history()
  .then (histories) ->
    histories.forEach (history) ->
      if history.current
        console.log chalk.green "* #{history.commit}\t#{history.date}"
      else
        console.log "  #{history.commit}\t#{history.date}"
  .catch (err) -> logger.warn err.message

_rollbackAction = (taskName, version) ->
  version = 1 if arguments.length is 2
  Promise.resolve()
  .then -> sneaky.getTask taskName
  .then (task) ->
    task.stdout.pipe process.stdout
    task.stderr.pipe process.stderr
    task.rollback version
  .catch (err) -> logger.warn err.message

module.exports = cli = ->

  commander.version pkg.version, '-v, --version'
  .usage '<command> taskName'

  commander.option '-T, --tasks', 'display the tasks'
  .on 'tasks', ->
    tasks = sneaky.getTasks()

    Object.keys tasks
    .forEach (key) ->
      task = tasks[key]
      console.log "#{task.taskName}\t\t#{task.description or ''}"

  commander.command 'deploy'
  .description 'deploy application to server'
  .action _deployAction

  commander.command 'history'
  .description 'display previous deploy histories'
  .action _historyAction

  commander.command 'rollback'
  .usage 'taskName [version]'
  .description 'rollback to the previous version'
  .action _rollbackAction

  commander.command 'd'
  .description 'alias of deploy'
  .action _deployAction

  commander.command 'h'
  .description 'alias of history'
  .action _historyAction

  commander.command 'r'
  .usage 'taskName [version]'
  .description 'alias of rollback'
  .action _rollbackAction

  commander.parse process.argv

  commander.help() if process.argv.length < 3
