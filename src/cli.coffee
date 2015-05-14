require 'coffee-script/register'
path = require 'path'
commander = require 'commander'
pkg = require '../package'
sneaky = require './sneaky'
# Load configuration file
require path.join process.cwd(), 'Skyfile'

module.exports = cli = ->

  commander.version pkg.version
  .usage '<command> [app:]env'

  commander.command 'deploy'
  .description 'deploy application to server'
  .action (taskName) ->
    [appName, envName] = taskName
    sneaky(appName).exec taskName

  commander.command 'd'
  .description 'alias of deploy'
  .action (taskName) ->
    [appName, envName] = taskName
    sneaky(appName).exec taskName

  commander.parse process.argv
