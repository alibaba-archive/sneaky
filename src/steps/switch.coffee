###*
 * Switch the current version of application
 * @param  {Object} task - Task instance
 * @return {Promise}
###
module.exports = (task) ->
  task.execRemoteCmd "cd #{task.path}; ln -sfn #{task.realpath} #{task.path}/current"
