commander = require('commander')
_ = require('underscore')
pkg = require('../package')
deploy = require('./deploy')
config = require('./config')

cli = ->
  commander.version(pkg.version)
    .usage('<command> [options] [projects]')

  _deployCommand = (cmd) ->
    cmd.usage('[options] [projects]')
      .option('-c, --config <config>', 'user defined configure file')
      .action ->
        options = _.last(arguments)
        _options =
          projects: _.first(arguments, arguments.length - 1)
          config: options.config or null
        deploy(_options)

  deployCommand = commander.command('deploy').description('deploy local projects to servers')
  deployAliasCommand = commander.command('d').description('alias of deploy')
  _deployCommand(deployCommand)
  _deployCommand(deployAliasCommand)

  _configCommand = (cmd) ->
    cmd.command('show').description('show configure files')
    cmd.command('add').description('add configure')
    cmd.command('edit').description('edit configure')
    cmd.option('-c, --config <config>', 'user defined configure file')
      .action ->
        options = _.last(arguments)
        action = _.first(arguments)
        action = if typeof action is 'string' then action else null
        _options =
          action: action
          configFile: options.config
        config(_options)

  configCommand = commander.command('config').description('add or update your configure file')
  configAliasCommand = commander.command('c').description('alias of config')
  _configCommand(configCommand)
  _configCommand(configAliasCommand)

  args = commander.parse(process.argv)
  commander.help() if process.argv.length < 3

module.exports = cli
