logger = require('graceful-logger')
{execCmd} = require('../util')

module.exports = (project, options, callback = ->) ->
  if project.before? and typeof project.before is 'string'
    prefix = project.name + '/'
    process.chdir("#{options.chdir}/#{prefix}")
    execCmd(project.before, callback)
  else
    callback(null)
