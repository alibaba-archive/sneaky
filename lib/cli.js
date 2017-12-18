/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let cli;
require('coffeescript/register');
const path = require('path');
const commander = require('commander');
const Promise = require('bluebird');
const fs = require('fs');
const logger = require('graceful-logger');
const chalk = require('chalk');

const pkg = require('../package');
const sneaky = require('./sneaky');

[
  'Skyfile',
  'skyfile',
  'skyfile.js',
  'Skyfile.js',
  'skyfile.coffee',
  'Skyfile.coffee'
].some(function(fileName) {
  const filePath = path.join(process.cwd(), fileName);
  try {
    if (fs.existsSync(filePath)) { return require(filePath); }
  } catch (err) {
    logger.warn(err.message);
    return process.exit(1);
  }
});

const _deployAction = taskName =>
  Promise.resolve()
  .then(function() { if (toString.call(taskName) !== '[object String]') { throw new Error("Invalid task name"); } })
  .then(() => sneaky.getTask(taskName))
  .then(function(task) {
    task.stdout.pipe(process.stdout);
    task.stderr.pipe(process.stderr);
    return task.deploy();}).catch(function(err) {
    logger.warn(err.message);
    return process.exit(1);
  })
;

const _historyAction = taskName =>
  Promise.resolve()
  .then(function() { if (toString.call(taskName) !== '[object String]') { throw new Error("Invalid task name"); } })
  .then(() => sneaky.getTask(taskName))
  .then(function(task) {
    task.stdout.pipe(process.stdout);
    task.stderr.pipe(process.stderr);
    return task.history();}).then(histories =>
    histories.forEach(function(history) {
      if (history.current) {
        return console.log(chalk.green(`* ${history.commit}\t${history.date}`));
      } else {
        return console.log(`  ${history.commit}\t${history.date}`);
      }
    })).catch(function(err) {
    logger.warn(err.message);
    return process.exit(1);
  })
;

const _rollbackAction = function(taskName, version) {
  if (arguments.length === 2) { version = 1; }
  return Promise.resolve()
  .then(function() { if (toString.call(taskName) !== '[object String]') { throw new Error("Invalid task name"); } })
  .then(() => sneaky.getTask(taskName))
  .then(function(task) {
    task.stdout.pipe(process.stdout);
    task.stderr.pipe(process.stderr);
    return task.rollback(version);}).catch(function(err) {
    logger.warn(err.message);
    return process.exit(1);
  });
};

const _forwardAction = function(taskName, version) {
  if (arguments.length === 2) { version = 1; }
  return Promise.resolve()
  .then(function() { if (toString.call(taskName) !== '[object String]') { throw new Error("Invalid task name"); } })
  .then(() => sneaky.getTask(taskName))
  .then(function(task) {
    task.stdout.pipe(process.stdout);
    task.stderr.pipe(process.stderr);
    return task.forward(version);}).catch(function(err) {
    logger.warn(err.message);
    return process.exit(1);
  });
};

module.exports = (cli = function() {

  commander.version(pkg.version, '-v, --version')
  .usage('<command> taskName');

  commander.option('-T, --tasks', 'display the tasks')
  .on('tasks', function() {
    const tasks = sneaky.getTasks();

    return Object.keys(tasks)
    .forEach(function(key) {
      const task = tasks[key];
      return console.log(`${task.taskName}\t\t${task.description || ''}`);
    });
  });

  commander.command('deploy')
  .usage('taskName [options]')
  .description('deploy application to server')
  .action(_deployAction);

  commander.command('history')
  .usage('taskName [options]')
  .description('display previous deploy histories')
  .action(_historyAction);

  commander.command('rollback')
  .usage('taskName [version]')
  .description('rollback to the previous version')
  .action(_rollbackAction);

  commander.command('forward')
  .usage('taskName [version]')
  .description('roll forward to the later version, opposite of rollback')
  .action(_forwardAction);

  commander.command('d')
  .usage('taskName [options]')
  .description('alias of deploy')
  .action(_deployAction);

  commander.command('h')
  .usage('taskName [options]')
  .description('alias of history')
  .action(_historyAction);

  commander.command('r')
  .usage('taskName [version]')
  .description('alias of rollback')
  .action(_rollbackAction);

  commander.command('f')
  .usage('taskName [version]')
  .description('alias of forward')
  .action(_forwardAction);

  commander.parse(process.argv);

  if (process.argv.length < 3) { return commander.help(); }
});
