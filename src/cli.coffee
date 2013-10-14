commander = require('commander')
_p = require('../package')
deploy = require('./deploy')

commander.version(_p.version).usage('<options> <projects>')
commander.option('-f, --force', 'Redeploy repos')
args = commander.parse(process.argv)

cli = ->
  options = {}
  options.force = args.force or false
  options.projects = args.args[0] if args.args[0]?
  deploy(options)

module.exports = cli