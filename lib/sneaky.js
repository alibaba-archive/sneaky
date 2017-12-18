/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Promise = require('bluebird');
const path = require('path');
const Task = require('./task');

const _tasks = {};

const sneaky = function(taskName, description, statement) {
  let task;
  if (_tasks[taskName]) {
    task = _tasks[taskName];
  } else {
    task = new Task;
    task.taskName = taskName;
  }

  if (toString.call(description) === '[object Function]') { statement = description; }
  if (toString.call(description) === '[object String]') { task.description = description; }
  if (toString.call(statement) === '[object Function]') { statement.apply(task, process.argv.slice(4)); }

  task.initialize();
  return _tasks[taskName] = task;
};

sneaky.getTask = function(taskName) {
  if (!_tasks[taskName]) {
    // Treat taskName as event name
    taskName = `${path.basename(process.cwd())}:${taskName}`;
  }
  if (!_tasks[taskName]) { throw new Error(`Task ${taskName} not found`); }
  return _tasks[taskName];
};

sneaky.getTasks = () => _tasks;

module.exports = (global.sneaky = sneaky);
