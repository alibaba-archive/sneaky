stream = require 'stream'
Promise = require 'bluebird'
Task = require './task'

class Mentor

  constructor: (appName, appStatement) ->
    @_appName = appName
    # Declare your application task settings
    @_appStatement = appStatement
    @_taskGroup = {}

    @stdout = new stream.Transform
    @stdout._transform = (chunk, encoding, callback) -> callback null, chunk
    @stderr = new stream.Transform
    @stderr._transform = (chunk, encoding, callback) -> callback null, chunk

  ###*
   * Declare specific task settings in different environments
   * @param  {String} env - Name of environment
   * @param  {Function} statement - Statement function
   * @return {Object} this - Task instance
  ###
  env: (env, statement) ->
    task = new Task
    taskName = if @_appName then "#{@_appName}:#{env}" else env
    @_taskGroup[taskName] = task
    # Apply the app statement first
    @_appStatement?.call? task, task
    statement.call task, task
    this

  # Execute the task
  exec: (taskNames...) ->
    self = this

    Promise.resolve taskNames
    .map (taskName) ->
      task = self._taskGroup[taskName]
      throw new Error("Task #{taskName} is not found!") unless task
      task.stdout.pipe self.stdout
      task.stderr.pipe self.stderr
      task.exec()

module.exports = Mentor
