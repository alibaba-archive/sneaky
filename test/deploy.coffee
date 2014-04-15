should = require('should')
path = require('path')
{exec} = require('child_process')
sneaky = path.join(__dirname, '../bin/sneaky')
config = path.join(__dirname, 'configs', "config.ini")
configHook = path.join(__dirname, 'configs', "config-hooks.ini")
fs = require('fs')

describe 'command#deploy', ->

  @timeout(30000)

  before (done) ->
    exec 'git submodule init; git submodule update; rm -rf ~/.sneaky', done

  describe 'deploy:allprojects', ->
    it 'should deploy all projects from the config file', (done) ->
      exec "#{sneaky} deploy -c #{path.join(__dirname, 'configs', 'config.ini')}", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('deploy finished') < 0
          return done('deploy error')
        done()

  describe 'deploy:chosen', ->
    it 'will deploy two repositories in one action', (done) ->
      exec "#{sneaky} deploy -c #{config} async ini_a", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('start deploy: async') < 0 or
           stdout.indexOf('start deploy: ini_a') < 0
          return done("deploy error")
        done()

  describe 'deploy:excludes', ->
    it 'will exclude [node_modules, tmp] in deployment', (done) ->
      exec "#{sneaky} deploy -c #{config} async", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('--exclude=node_modules --exclude=tmp') < 0
          return done("deploy error")
        done()

  describe 'deploy:hooks', ->
    it 'will run hooks before/after rsync', (done) ->
      exec "#{sneaky} deploy -c #{configHook}", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('LICENSE') < 0
          return done('deploy error')
        done()

  describe 'deploy:repos', ->
    it 'will deploy with repos configure file', (done) ->
      process.chdir(path.join(__dirname, './ini'))
      exec "cp ../configs/config-ini.ini ./.sneakyrc && #{sneaky} deploy", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('start deploy: ini_a') < 0
          return done('deploy error')
        fs.unlink('./.sneakyrc', done)

  describe 'deploy:remotePath', ->
    it 'will deploy with remote path', (done) ->
      exec "#{sneaky} -c #{path.join(__dirname, './configs/config-ini-remote.ini')} deploy", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('deploy finished') < 0
          return done('deploy error')
        done()
