should = require 'should'
logger = require 'graceful-logger'
chalk = require 'chalk'
Task = require '../src/task'
sneaky = require '../src/sneaky'

if process.env.PLATFORM is 'travis'
  # Hack on test cases
  __execCmd = Task.prototype._execCmd
  Task.prototype._execCmd = (cmd) ->
    if cmd.indexOf('rsync') is 0
      # Slice the ssh part of rsync
      cmd = cmd.replace /\-e.*?\:/, ''

    __execCmd.call this, cmd
  # Do not execute command on remote server
  Task.prototype._wrapRemoteCmd = (cmd) ->
    cmd = "cd #{task.targetPath} && #{cmd}" unless cmd.indexOf('cd ') is 0
    cmd

task = sneaky 'sneaky:deploy', ->

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

task.stdout.pipe process.stdout
task.stderr.pipe process.stderr

describe 'Deploy', ->

  it 'should deploy the master branch of project to server', (done) ->

    output = ''

    task.stdout.on 'data', (data) -> output += data

    task.deploy()
    .delay 1
    .then ->
      output.should.containEql "Sneaky: '0.1.1'"
      done()
    .catch done

describe 'History', ->

  it 'should display histories of project', (done) ->

    task.history()
    .delay 1
    .map (history) ->
      history.should.have.properties 'date', 'current', 'commit'
    .then -> done()
    .catch done

describe 'Rollback & Forward', ->

  before (done) ->
    task.version = 'v0.2.0'
    task.deploy()
    .delay 1
    .then -> done()
    .catch done

  it 'should rollback to the previous version', (done) ->

    output = ''

    task.stdout.on 'data', (data) -> output += data

    task.rollback()
    .delay 1
    .then ->
      # Contain the previous version by rollback
      output.should.containEql "Sneaky: '0.1.1'"
      done()
    .catch done

  it 'should forward to the last version', (done) ->
    output = ''

    task.stdout.on 'data', (data) -> output += data

    task.forward()
    .delay 1
    .then ->
      output.should.containEql "Sneaky: '0.2.0'"
      done()
    .catch done
