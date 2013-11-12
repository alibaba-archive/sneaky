commander = require('commander')
_p = require('../package')
deploy = require('./deploy')

commander.version(_p.version).usage('<command> <options> <projects>')

commander.option('-f, --force', 'redeploy repository')
commander.option('-c, --config', 'user defined configure file')

args = commander.parse(process.argv)

cli = ->
  options = {}
  options.force = args.force or false
  options.projects = args.args[0] if args.args[0]?
  deploy(options)

module.exports = cli
