path = require 'path'
async = require 'async'
{execCmd} = require '../util'

parser =
  excludes: (project) ->
    return '' unless project.excludes?.length
    excludes = project.excludes.map (item) -> "--exclude=#{item}"
    return excludes.join(' ')
  includes: (project) ->
    return '' unless project.includes?.length
    includes = project.includes.map (item) -> "--include=#{item}"
    return includes.join(' ')

parse = (project, options, dest) ->
  {destination, user, host, port} = dest
  port or= 22

  # Hack for only
  if project.only?.length
    project.excludes = ['*']
    project.includes = project.only

  if project.nochdir
    sourceDir = process.cwd()
  else
    sourceDir = path.join(options.chdir, project.name)

  if user? and host?  # remote server
    cmd = [
      "rsync -a --delete-after --ignore-errors --force"
      "-e \"ssh -p #{port}\""
      parser.includes(project)
      parser.excludes(project)
      "#{sourceDir}/"
      "#{user}@#{host}:#{destination}"
    ].join ' '
  else  # local destination
    cmd = [
      "rsync -a --timeout=15 --delete-after --ignore-errors --force"
      parser.includes(project)
      parser.excludes(project)
      "#{sourceDir}/"
      destination
    ].join ' '
  return cmd

module.exports = (project, options, callback = ->) ->
  unless project.destinations?.length
    return callback(new Error("missing destinations in project: #{project.name}"))
  async.eachSeries project.destinations, (dest, next) ->
    cmd = parse(project, options, dest)
    execCmd(cmd, next)
  , callback
