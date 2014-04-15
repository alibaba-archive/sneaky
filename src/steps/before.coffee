logger = require('graceful-logger')
{execCmd} = require('../util')

module.exports = (project, options, callback = ->) ->
  if project.before? and typeof project.before is 'string'
    if project.nochdir
      process.chdir("#{project.source}") if project.source?
    else  # Change to temp directory without nochdir flag
      prefix = project.name + '/'
      process.chdir("#{options.chdir}/#{prefix}")
    execCmd(project.before, callback)
  else
    callback()
