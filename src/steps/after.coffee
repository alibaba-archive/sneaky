async = require('async')
{execCmd} = require('../util')

parse = (project, options, i) ->
  destination = project.destinations[i]
  if destination.indexOf('@') is -1
    cmd = project.after
  else
    [server, dest] = destination.split(':')
    port = project.ports?[i] or 22
    cmd = """
      ssh -t -t #{server} -p #{port} \"#{project.after}\"
    """
  return cmd

module.exports = (project, options, callback = ->) ->
  unless typeof project.after is 'string'
    return callback()

  prefix = project.name + '/'
  count = project.destinations?.length
  return callback() unless count

  async.times count, (i, next) ->
    cmd = parse(project, options, i)
    execCmd(cmd, next)
  , callback
