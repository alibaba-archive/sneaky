should = require 'should'
_ = require 'underscore'
path = require 'path'
{exec} = require 'child_process'
sneaky = path.join __dirname, '../bin/sneaky'
configFile = path.join __dirname, 'configs', "config.json"
hookConfigFile = path.join __dirname, 'configs', "hooks.json"
fs = require 'fs'

clean = (done) -> exec('rm -rf /tmp/async /tmp/ini /tmp/ini_a tmp/ini_b', done)

describe 'command#deploy', ->

  @timeout(30000)

  before (done) ->
    exec 'git submodule init; git submodule update; rm -rf ~/.sneaky', done

  describe 'deploy:allprojects', ->

    before clean

    it 'should deploy all projects from the config file', (done) ->
      exec "#{sneaky} deploy -c #{configFile}", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('deploy finished') < 0
          return done('deploy error')
        done()

  describe 'deploy:chosen', ->

    before clean

    it 'will deploy two repositories in one action', (done) ->
      exec "#{sneaky} deploy -c #{configFile} async ini_a", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('start deploy: async') < 0 or
           stdout.indexOf('start deploy: ini_a') < 0
          return done("deploy error")
        done()

  describe 'deploy:excludes', ->

    before clean

    it 'should exclude [node_modules, tmp] in deployment', (done) ->
      exec "#{sneaky} deploy -c #{configFile} async", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('--exclude=node_modules --exclude=tmp') < 0
          return done("deploy error")
        done()

  describe 'deploy:includes', ->

    before clean

    it 'should include [lib, test] in deployment', (done) ->
      exec "#{sneaky} deploy -c #{path.join(__dirname, 'configs/includes.json')}", (err, stdout, stderr) ->
        return done(err) if err?
        files = fs.readdirSync('/tmp/async')
        files.indexOf('lib').should.not.eql(-1)
        files.indexOf('test').should.not.eql(-1)
        done()

  describe 'deploy:only', ->

    before clean

    it 'should only deploy [lib, .gitignore] to server', (done) ->
      exec "#{sneaky} deploy -c #{path.join(__dirname, 'configs/only.json')}", (err, stdout, stderr) ->
        return done(err) if err?
        files = fs.readdirSync('/tmp/async')
        files.indexOf('lib').should.not.eql(-1)
        files.indexOf('.gitignore').should.not.eql(-1)
        done()

  describe 'deploy:hooks', ->

    before clean

    it 'will run hooks before/after rsync', (done) ->
      exec "#{sneaky} deploy -c #{hookConfigFile}", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('LICENSE') < 0
          return done('deploy error')
        done()

  describe 'deploy:repos', ->

    before clean

    it 'will deploy with repos configure file', (done) ->
      process.chdir(path.join(__dirname, './ini'))
      config =
        production:
          destinations: ["/tmp/async"]
      fs.writeFile '.sneakyrc', JSON.stringify(config, null, 2), ->
        exec "#{sneaky} deploy", (err, stdout, stderr) ->
          return done(err) if err?
          if stdout.indexOf('start deploy: ini-production') < 0
            return done('deploy error')
          fs.unlinkSync('./.sneakyrc')
          process.chdir path.join(__dirname, '..')
          done()

  describe 'deploy:remote', ->

    before clean

    it 'will deploy with remote path', (done) ->
      child = exec "#{sneaky} -c #{path.join(__dirname, './configs/remote.json')} deploy", (err, stdout, stderr) ->
        if stdout.indexOf('deploy finished') < 0 then done('deploy error') else done(err)

  describe 'deploy:nochdir', ->

    before clean

    it 'should not use git archive and not change dir', (done) ->
      exec "#{sneaky} -c #{path.join(__dirname, 'configs/nochdir.json')} deploy", (err, stdout, stderr) ->
        return done(err) if err?
        stdout.indexOf('git archive').should.eql(-1)
        done()

  describe 'deploy:expand', ->

    before clean

    it 'should deploy with the expanded destinations', (done) ->
      exec "#{sneaky} -c #{path.join(__dirname, 'configs/expand.js')} deploy", (err, stdout, stderr) ->
        if stdout.indexOf('deploy finished') < 0 then done('deploy error') else done(err)
