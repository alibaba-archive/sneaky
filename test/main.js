/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const should = require('should');
const Promise = require('bluebird');
const logger = require('graceful-logger');
const chalk = require('chalk');
const Task = require('../lib/task');
const sneaky = require('../lib/sneaky');

// Mocks
const __execCmd = Task.prototype._execCmd;
Task.prototype._execCmd = function(cmd) {
  this.emit(cmd.split(' ')[0], cmd);
  if (cmd.indexOf('rsync') === 0) {
    // Slice the ssh part of rsync
    cmd = cmd.replace(/\-e.*?\:/, '');
  }
  return __execCmd.call(this, cmd);
};
// Do not execute command on remote server
Task.prototype._wrapRemoteCmd = function(cmd) {
  this.emit(cmd.split(' ')[0], cmd);
  if (cmd.indexOf('cd ') !== 0) { cmd = `cd ${this.targetPath} && ${cmd}`; }
  return cmd;
};

describe('Deploy && History && Rollback && Forward', function() {

  const task = sneaky('d1', function() {
    this.user = 'jarvis';
    this.host = '192.168.0.21';
    this.port = 22;
    this.path = '/tmp/sneaky';
    this.version = 'v0.1.1';
    // Ignore the lib directory
    this.filter = `\
- lib
- node_modules\
`;
    this.before('coffee -o lib -c lib');
    return this.after('npm version');
  });

  it('should deploy the master branch of project to server', function(done) {

    const $checkCmd = new Promise(function(resolve, reject) {
      return task.once('rsync', function(cmd) {
        try {
          cmd.should.containEql('rsync -az --delete-after --force --filter="- lib" --filter="- node_modules"');
          cmd.should.containEql('-e "ssh -p 22" jarvis@192.168.0.21:');
          cmd.should.containEql('-v0.1.1');
          return resolve();
        } catch (err) {
          return reject(err);
        }
      });
    });

    const $deploy = task.deploy();

    return Promise.all([$checkCmd, $deploy])
    .nodeify(done);
  });

  it('should display histories of project', done =>
    task.history().map(history => {
      history.should.have.properties('date', 'current', 'commit')
    }).nodeify(done)
  );

  it('should rollback to the previous version', function(done) {

    task.version = 'v0.2.0';

    const $checkCmd = new Promise(function(resolve, reject) {
      return task.on('cd', function(cmd) {
        try {
          if (cmd.indexOf('v0.1.1') > -1) {
            task.removeListener('cd', function() {});
            return resolve();
          }
        } catch (err) {
          return reject(err);
        }
      });
    });

    const $v2 = task.deploy();

    const $rollback = $v2.then(() => task.rollback());

    return Promise.all([$checkCmd, $v2, $rollback])
    .nodeify(done);
  });

  return it('should forward to the last version', function(done) {

    const $checkCmd = new Promise(function(resolve, reject) {
      return task.on('cd', function(cmd) {
        try {
          if (cmd.indexOf('0.2.0') > -1) {
            task.removeListener('cd', function() {});
            return resolve();
          }
        } catch (err) {
          return reject(err);
        }
      });
    });

    const $forword = task.forward();

    return Promise.all([$checkCmd, $forword])
    .nodeify(done);
  });
});

describe('Set deployPath to a sub directory', () =>

  it('should only deploy the files under lib directory', function(done) {

    const task1 = sneaky('d2', function() {
      this.user = 'jarvis';
      this.host = '192.168.0.21';
      this.port = 22;
      this.path = '/tmp/sneaky';
      this.version = 'v0.1.1';
      return this.deployPath = 'lib';
    });

    const $checkCmd = new Promise(function(resolve, reject) {
      return task1.once('rsync', function(cmd) {
        try {
          cmd.should.containEql('/deploy/lib');
          return resolve();
        } catch (err) {
          return reject(err);
        }
      });
    });

    const $deploy = task1.deploy();

    return Promise.all([$checkCmd, $deploy])
    .nodeify(done);
  })
);
