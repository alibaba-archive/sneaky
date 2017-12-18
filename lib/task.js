/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const path = require('path');
const stream = require('stream');
const {exec, spawn} = require('child_process');
const {EventEmitter} = require('events');
const fs = require('fs');
const logger = require('graceful-logger');
const moment = require('moment');
const Promise = require('bluebird');
Promise.promisifyAll(fs);

class Task extends EventEmitter {

  constructor() {
    super()
    this._preHooks = {};
    this._postHooks = {};
    this._steps = [{
      stepName: 'prepare',
      executor: require('./steps/prepare')
    }
    , {
      stepName: 'transport',
      executor: require('./steps/transport')
    }
    ];
    this.stdout = new stream.Transform;
    this.stdout._transform = (chunk, encoding, callback) => callback(null, chunk);
    this.stderr = new stream.Transform;
    this.stderr._transform = (chunk, encoding, callback) => callback(null, chunk);
  }

  initialize() {
    const task = this;
    if (!task.appName) { task.appName = task.taskName.split(':')[0]; }
    if (!task.taskName) { task.taskName = path.basename(process.cwd()); }
    if (!task.source) { task.source = process.cwd(); }
    if (!task.port) { task.port = 22; }
    if (!task.path) { throw new Error(`Task ${task.taskName}'s path is undefined`); }
  }

  /**
   * Execute this deploy process
   * @return {Promise} The task with the finishd state
  */
  deploy() {
    const task = this;

    logger.info(`start deploy ${task.taskName}`);

    return Promise.resolve()

    .then(() => task._steps)

    .each(function(step) {
      const {stepName, executor} = step;
      let $executor = Promise.resolve();
      const {_preHooks, _postHooks} = task;

      if (_preHooks[stepName]) {
        $executor = $executor.then(() => _preHooks[stepName])
        .each(fn => fn.call(task, task));
      }

      $executor = $executor.then(() => executor.call(task, task));

      if (_postHooks[stepName]) {
        $executor = $executor.then(() => _postHooks[stepName])
        .each(fn => fn.call(task, task));
      }

      return $executor;}).then(function() {
      process.chdir(task.source);
      return logger.info(`finish deploy ${task.taskName}`);
    });
  }

  history() {
    const task = this;
    return Promise.resolve()
    .then(function() {
      const sshCmd = task._wrapRemoteCmd(`cd ${task.path}; ls -l | tail -n 30`);
      return new Promise(function(resolve, reject) {
        let child;
        return child = exec(sshCmd, function(err, out) {
          if (err) { return reject(err); }
          return resolve(out);
        });
      });}).then(function(out) {
      let histories;
      let current = '';
      return histories = out.split('\n')
      .map(function(line) {
        let matches;
        if (/current/.test(line)) {
          current = path.basename(line).trim();
        } else if (matches = line.match(/\d{14}\-.*/i)) {
          return matches[0].trim();
        }
        return false;}).filter(history => history)
      .map(function(history) {
        const [date, ...commit] = Array.from(history.split('-'));
        const m = moment(date, 'YYYYMMDDHHmmss');

        return {
          date: m.format('YYYY-MM-DD HH:mm:ss'),
          commit: commit.join('-'),
          current: current === history ? true : false,
          dirname: history,
          path: path.join(task.path, history)
        };
      });
    });
  }

  _rollto(version, direction) {
    if (version == null) { version = 1; }
    if (direction == null) { direction = 'down'; }
    const task = this;

    // Version maybe string typed
    // Rollback to the specific version
    if (!isNaN(Number(version))) { version = Number(version); }

    return task.history()

    .then(function(histories) {
      let meetCurrent = false;
      let chosenHistory = false;
      const diffNum = 0;
      const totalCount = histories.length;

      if (direction === 'down') { histories = histories.reverse(); }

      histories.some(function(history, idx) {
        if (history.current) { meetCurrent = true; }
        if (!meetCurrent) { return; }
        // Roll to the first/last version
        if (version === 'edge') {
          if (idx === (totalCount - 1)) {
            chosenHistory = history;
            return true;
          }
        // Roll to the specific version
        } else if (toString.call(version) === '[object String]') {
          if (history.commit.indexOf(version) > -1) {
            chosenHistory = history;
            return true;
          }
        // Roll by number
        } else if (toString.call(version) === '[object Number]') {
          if (version === 0) {
            chosenHistory = history;
            return true;
          }
          version -= 1;
        } else {
          throw new Error(`Invalid version '${version}'`);
        }
        return false;
      });

      if (!chosenHistory) { throw new Error(`Can not find the rollback version '${version}'`); }

      const cmd = `cd ${task.path}; ln -sfn ${chosenHistory.path} ${path.join(task.path, 'current')}`;
      return task.execRemoteCmd(cmd)
      .then(() => task.targetPath = chosenHistory.path);}).then(function() {
      // Execute the hooks after transport
      if (__guard__(task._postHooks != null ? task._postHooks.transport : undefined, x => x.length)) {
        return Promise.resolve(task._postHooks.transport)
        .each(fn => fn.call(task, task));
      }
    });
  }

  rollback(version) {
    if (version == null) { version = 1; }
    logger.info(`start rollback ${this.taskName} to version ${version}`);

    if (version === 'first') { version = 'edge'; }

    return this._rollto(version, 'down');
  }

  forward(version) {
    if (version == null) { version = 1; }
    logger.info(`start forward ${this.taskName} to version ${version}`);

    if (version === 'last') { version = 'edge'; }

    return this._rollto(version, 'up');
  }

  /**
   * Register pre hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Promise}
  */
  pre(stepName, fn) {
    if (!this._preHooks[stepName]) { this._preHooks[stepName] = []; }
    return this._preHooks[stepName].push(fn);
  }

  /**
   * Register post hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Function}
  */
  post(stepName, fn) {
    if (!this._postHooks[stepName]) { this._postHooks[stepName] = []; }
    return this._postHooks[stepName].push(fn);
  }

  /**
   * Execute script before transport
   * It is an alias function of `execCmd` before `transport` step
   * @param  {String} stepName - Name of step
   * @param  {String|Function} script - Script string or function
   * @return {Function}
  */
  before(stepName, script) {
    let fn;
    if (arguments.length === 1) {
      script = stepName;
      stepName = 'transport';
    }
    if (toString.call(script) === '[object Function]') {
      fn = script;
    } else {
      fn = () => this.execCmd(script);
    }
    return this.pre(stepName, fn);
  }

  /**
   * Execute remote script after transport and linking to the new directory
   * It is an alias function of `execRemoteCmd` after `transport` step
   * @param  {String} stepName - Name of step
   * @param  {String|Function} script - Script string or function
   * @return {Function}
  */
  after(stepName, script) {
    let fn;
    if (arguments.length === 1) {
      script = stepName;
      stepName = 'transport';
    }
    if (toString.call(script) === '[object Function]') {
      fn = script;
    } else {
      fn = () => this.execRemoteCmd(script);
    }
    return this.post(stepName, fn);
  }

  _execCmd(cmd) {
    const task = this;
    return new Promise(function(resolve, reject) {
      const child = exec(cmd, function(err, out) {
        if (err) { return reject(err); }
        return resolve(out);
      });
      child.stdout.on('data', data => task.stdout.write(data));
      return child.stderr.on('data', data => task.stderr.write(data));
    });
  }

  _wrapRemoteCmd(cmd) {
    const task = this;
    // Change directory to remote working directory
    if (cmd.indexOf('cd ') !== 0) { cmd = `cd ${task.targetPath} && ${cmd}`; }
    let sshCmd = "ssh";
    if (task.port) { sshCmd += ` -p ${task.port}`; }
    if (task.key) { sshCmd += ` -i ${task.key}`; }
    sshCmd += ` ${task.user}@${task.host}`;
    sshCmd += ` \"${cmd}\"`;
    return sshCmd;
  }

  /**
   * Execute shell on localhost
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  */
  execCmd(cmd) {
    logger.info(cmd);
    return this._execCmd(cmd);
  }

  /**
   * Execute shell on remote servers
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  */
  execRemoteCmd(cmd) {
    const sshCmd = this._wrapRemoteCmd(cmd);
    logger.info(sshCmd);
    return this._execCmd(sshCmd);
  }
}

module.exports = Task;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
