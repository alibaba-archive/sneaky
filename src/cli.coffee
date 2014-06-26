commander = require 'commander'
_ = require 'underscore'
pkg = require '../package'
deploy = require './deploy'
config = require './config'
util = require './util'

actions =
  deploy: ->
    options = _.last(arguments)
    _options =
      projects: _.first(arguments, arguments.length - 1)
      config: options.config or null
    deploy(_options)
  config: ->
    options = _.last(arguments)
    action = _.first(arguments)
    action = if typeof action is 'string' then action else null
    _options =
      action: action
      configFile: options.config
    config(_options)

cli = ->
  commander.version(pkg.version)
    .usage('<command> [options] [projects]')

  commander.command('deploy')
    .description('deploy local projects to servers')
    .option('-c, --config <config>', 'user defined configure file')
    .usage('[options] [projects]')
    .action(actions.deploy)

  commander.command('d')
    .description('(alias) of deploy')
    .option('-c, --config <config>', 'user defined configure file')
    .usage('[options] [projects]')
    .action(actions.deploy)

  commander.command('config')
    .description('add or update your configure file')
    .option('-c, --config <config>', 'user defined configure file')
    .usage('show|add|edit')
    .action(actions.config)

  commander.command('c')
    .description('(alias) of config')
    .option('-c, --config <config>', 'user defined configure file')
    .usage('show|add|edit')
    .action(actions.config)

  commander.parse(process.argv)
  commander.help() if process.argv.length < 3

module.exports = cli
