should = require 'should'
sneaky = require '../src/sneaky'

task = sneaky 'sneaky:deploy', ->

  @user = 'jarvis'

  @host = '192.168.0.21'

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
    .then ->
      output.should.containEql "Sneaky: '0.1.1'"
      done()
    .catch done

describe 'History', ->

  it 'should display histories of project', (done) ->

    task.history()
    .map (history) ->
      history.should.have.properties 'date', 'current', 'commit'
    .then -> done()
    .catch done

describe 'Rollback', ->

  before (done) ->
    task.version = 'v0.2.0'
    task.deploy()
    .then -> done()
    .catch done

  it 'should rollback to the previous version', (done) ->

    output = ''

    task.stdout.on 'data', (data) -> output += data

    task.rollback()
    .then ->
      # Contain the previous version by rollback
      output.should.containEql "Sneaky: '0.1.1'"
      done()
    .catch done
