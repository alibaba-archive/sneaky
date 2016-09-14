Promise = require 'bluebird'
path = require 'path'
Task = require './task'

_tasks = {}

sneaky = (taskName, description, statement) ->
  if _tasks[taskName]
    task = _tasks[taskName]
  else
    task = new Task
    task.taskName = taskName

  statement = description if toString.call(description) is '[object Function]'
  task.description = description if toString.call(description) is '[object String]'
  statement.apply task, process.argv[4..] if toString.call(statement) is '[object Function]'

  task.initialize()
  _tasks[taskName] = task

sneaky.getTask = (taskName) ->
  unless _tasks[taskName]
    # Treat taskName as event name
    taskName = "#{path.basename(process.cwd())}:#{taskName}"
  throw new Error("Task #{taskName} not found") unless _tasks[taskName]
  _tasks[taskName]

sneaky.getTasks = -> _tasks

module.exports = global.sneaky = sneaky
