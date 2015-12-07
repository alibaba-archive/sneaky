should = require 'should'
Promise = require 'bluebird'
logger = require 'graceful-logger'
chalk = require 'chalk'
Task = require '../src/task'
sneaky = require '../src/sneaky'

# Mocks
__execCmd = Task.prototype._execCmd
Task.prototype._execCmd = (cmd) ->
  @emit cmd.split(' ')[0], cmd
  if cmd.indexOf('rsync') is 0
    # Slice the ssh part of rsync
    cmd = cmd.replace /\-e.*?\:/, ''
  __execCmd.call this, cmd
# Do not execute command on remote server
Task.prototype._wrapRemoteCmd = (cmd) ->
  @emit cmd.split(' ')[0], cmd
  cmd = "cd #{@targetPath} && #{cmd}" unless cmd.indexOf('cd ') is 0
  cmd

describe 'Deploy && History && Rollback && Forward', ->

  task = sneaky 'd1', ->
    @user = 'jarvis'
    @host = '192.168.0.21'
    @port = 22
    @path = '/tmp/sneaky'
    @version = 'v0.1.1'
    # Ignore the src directory
    @filter = '''
    - src
    - node_modules
    '''
    @before 'coffee -o lib -c src'
    @after 'npm version'

  it 'should deploy the master branch of project to server', (done) ->

    $checkCmd = new Promise (resolve, reject) ->
      task.once 'rsync', (cmd) ->
        try
          cmd.should.containEql 'rsync -az --delete-after --force --filter="- src" --filter="- node_modules"'
          cmd.should.containEql '-e "ssh -p 22" jarvis@192.168.0.21:'
          cmd.should.containEql '-v0.1.1'
          resolve()
        catch err
          reject err

    $deploy = task.deploy()

    Promise.all [$checkCmd, $deploy]
    .nodeify done

  it 'should display histories of project', (done) ->

    task.history().map (history) ->
      history.should.have.properties 'date', 'current', 'commit'
    .nodeify done

  it 'should rollback to the previous version', (done) ->

    task.version = 'v0.2.0'

    $checkCmd = new Promise (resolve, reject) ->
      task.on 'cd', (cmd) ->
        try
          if cmd.indexOf('v0.1.1') > -1
            task.removeListener 'cd', ->
            resolve()
        catch err
          reject err

    $v2 = task.deploy()

    $rollback = $v2.then -> task.rollback()

    Promise.all [$checkCmd, $v2, $rollback]
    .nodeify done

  it 'should forward to the last version', (done) ->

    $checkCmd = new Promise (resolve, reject) ->
      task.on 'cd', (cmd) ->
        try
          if cmd.indexOf('0.2.0') > -1
            task.removeListener 'cd', ->
            resolve()
        catch err
          reject err

    $forword = task.forward()

    Promise.all [$checkCmd, $forword]
    .nodeify done

describe 'Set deployPath to a sub directory', ->

  it 'should only deploy the files under src directory', (done) ->

    task1 = sneaky 'd2', ->
      @user = 'jarvis'
      @host = '192.168.0.21'
      @port = 22
      @path = '/tmp/sneaky'
      @version = 'v0.1.1'
      @deployPath = 'src'

    $checkCmd = new Promise (resolve, reject) ->
      task1.once 'rsync', (cmd) ->
        try
          cmd.should.containEql '/deploy/src'
          resolve()
        catch err
          reject err

    $deploy = task1.deploy()

    Promise.all [$checkCmd, $deploy]
    .nodeify done
