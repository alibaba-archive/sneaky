commander = require('commander')
_ = require('underscore')
pkg = require('../package')
deploy = require('./deploy')
config = require('./config')

cli = ->
  commander.version(pkg.version)
    .usage('<command> [options] [projects]')

  commander.command('deploy')
    .usage('[options] [projects]')
    .description('deploy local projects to servers')
    .option('-c, --config <config>', 'user defined configure file')
    .option('-f, --force', 'force deploy repository')
    .action ->
      options = _.last(arguments)
      _options =
        projects: _.first(arguments, arguments.length - 1)
        force: options.force or false
        config: options.config or null
      deploy(_options)

  configCommand = commander.command('config')

  configCommand.command('show')
    .description('show configure files')

  configCommand.command('add')
    .description('add configure')

  configCommand.command('edit')
    .description('edit configure')

  configCommand.description('add or update your configure file')
    .option('-c, --config <config>', 'user defined configure file')
    .action ->
      options = _.last(arguments)
      action = _.first(arguments)
      action = if typeof action is 'string' then action else null
      _options =
        action: action
        configFile: options.config
      config(_options)

  args = commander.parse(process.argv)

  commander.help() if process.argv.length < 3

module.exports = cli
