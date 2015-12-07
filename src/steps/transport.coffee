path = require 'path'

###*
 * Rsync files to remote server
 * @param  {Object} task - Task instance
 * @return {Promise}
###
module.exports = (task) ->
  cmd = "rsync -az --delete-after --force"

  # Add filters
  if toString.call(task.filter) is '[object String]'
    task.filter.split('\n').forEach (filter) ->
      cmd += " --filter=\"#{filter.trim()}\""

  # Add source destination
  if task.deployPath then task.srcPath = path.join task.srcPath, task.deployPath

  cmd += " #{path.join(task.srcPath, '/')}"

  # Add remote destination
  cmd += " -e \"ssh -p #{task.port}\" #{task.user}@#{task.host}:#{task.targetPath}"

  task.execRemoteCmd "cd ~/ && mkdir -p #{task.targetPath}"

  .then -> task.execCmd cmd

  .then -> task.execRemoteCmd "cd #{task.path}; ln -sfn #{task.targetPath} #{task.path}/current"
