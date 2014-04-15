async = require('async')
{execCmd} = require('../util')

parser =
  excludes: (project) ->
    return '' unless project.excludes?.length
    excludes = project.excludes.map (item) -> "--exclude=#{item}"
    return excludes.join(' ')
  includes: (project) ->
    return '' unless project.includes?.length
    includes = project.includes.map (item) -> "--include=#{item}"
    return includes.join(' ')

parse = (project, options, i) ->
  destination = project.destinations[i]
  port = project.ports?[i] or 22

  # Hack for only
  if project.only?.length
    project.excludes = ['*']
    project.includes = project.only

  if destination.indexOf('@') is -1  # remote server
    cmd = """
    rsync -a --timeout=15 --delete-after --ignore-errors --force \\
    #{parser.includes(project)} \\
    #{parser.excludes(project)} \\
    #{options.chdir}/#{project.name}/ #{destination}
    """
  else  # local destination
    cmd = """
    rsync -a --timeout=15 --delete-after --ignore-errors --force \\
    -e \"ssh -p #{port}\" \\
    #{parser.includes(project)} \\
    #{parser.excludes(project)} \\
    #{options.chdir}/#{project.name}/ #{destination}
    """
  return cmd

module.exports = (project, options, callback = ->) ->
  count = project.destinations?.length
  unless count
    return callback(new Error("missing destinations in project: #{project.name}"))
  async.times count, (i, next) ->
    cmd = parse(project, options, i)
    execCmd(cmd, next)
  , callback
