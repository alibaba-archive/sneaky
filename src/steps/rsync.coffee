async = require('async')
{execCmd} = require('../util')

parse = (project, options, i) ->
  destination = project.destinations[i]
  if project.excludes?.length
    excludes = project.excludes.map (item) -> "--exclude=#{item}"
  else
    excludes = []
  port = project.ports?[i] or 22
  if destination.indexOf('@') is -1  # remote server
    cmd = """
    rsync -a --timeout=15 --delete-after --ignore-errors --force \\
    #{excludes.join(' ')} \\
    #{options.chdir}/#{project.name}/ #{destination}
    """
  else  # local destination
    cmd = """
    rsync -a --timeout=15 --delete-after --ignore-errors --force \\
    -e \"ssh -p #{port}\" #{excludes.join(' ')} \\
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
