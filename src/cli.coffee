commander = require('commander')
_ = require('underscore')
_p = require('../package')
deploy = require('./deploy')
init = require('./init')
config = require('./config')

cli = ->
  commander.version(_p.version)
    .usage('<command> [options] [projects]')

  commander.command('deploy')
    .usage('[options] [projects]')
    .description('deploy local projects to servers')
    .option('-f, --force', 'force deploy repository')
    .option('-c, --config <config>', 'user defined configure file')
    .action ->
      options = _.last(arguments)
      _options =
        projects: _.first(arguments, arguments.length - 1)
        force: options.force or false
        config: options.config or null
      deploy(_options)

  commander.command('init')
    .description('init configure file in ~/.sneakyrc')
    .action ->
      console.log 'comming soon'

  commander.command('config')
    .description('add or update your configure file')
    .action ->
      console.log 'comming soon'

  commander.parse(process.argv)

module.exports = cli
