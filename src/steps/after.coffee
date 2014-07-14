async = require('async')
{execCmd} = require('../util')

parse = (project, options, dest) ->
  {destination, user, host, port} = dest
  port or= 22
  if user? and host?  # remote server
    cmd = "ssh -t -t #{user}@#{host} -p #{port} \"#{project.after}\""
  else  # local server
    cmd = project.after
  return cmd

module.exports = (project, options, callback = ->) ->
  unless typeof project.after is 'string'
    return callback()
  return callback() unless project.destinations?.length
  async.eachSeries project.destinations, (dest, next) ->
    cmd = parse(project, options, dest)
    execCmd(cmd, next)
  , callback
