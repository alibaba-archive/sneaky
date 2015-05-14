path = require 'path'

###*
 * Rsync files to remote server
 * @param  {Object} task - Task instance
 * @return {Promise}
###
module.exports = (task) ->
  cmd = "rsync -az --delete-after --force"

  # Add filters
  if toString.call task.filter is '[object String]'
    task.filter.split('\n').forEach (filter) ->
      cmd += " --filter=\"#{filter}\""

  # Add source destination
  cmd += " #{task.rsyncSource}"

  # Add remote destination
  cmd += " -e \"ssh -p #{task.port}\" #{task.user}@#{task.host}:#{task.realPath}"

  task.execCmd cmd
