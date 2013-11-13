should = require('should')
path = require('path')
{exec} = require('child_process')
{execCommand} = require('./util')
sneaky = path.join(__dirname, '../bin/sneaky')
local = process.env.local or ''
config = path.join(__dirname, "config#{local}.ini")
configHook = path.join(__dirname, "config-hooks#{local}.ini")

describe 'command#deploy', ->

  before (done) ->
    exec 'rm -rf ~/.sneaky', (err) -> done(err)

  describe 'deploy:allprojects', ->
    @timeout(10000)

    it 'should deploy all projects from the config file', (done) ->
      execCommand "#{sneaky} deploy -c #{config}", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('Finish deploy') < 0
          return done('deploy error')
        done()

  describe 'deploy:redeploy', ->
    @timeout(10000)

    it 'should not deploy without the `-f` option', (done) ->
      execCommand "#{sneaky} deploy -c #{config}", (err, stdout, stderr) ->
        return done(err) if err?
        if stderr.indexOf('skipping...') < 0
          done('should not deploy twice!')
        done()

  describe 'deploy:force:deploy', ->
    @timeout(10000)

    it 'can be deployed more than once with the `-f` option', (done) ->
      execCommand "#{sneaky} deploy -c #{config} -f async", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('Finish deploy [async]') < 0
          return done('deploy error')
        done()

  describe 'deploy:chosen', ->
    @timeout(10000)

    it 'will deploy two repositories in one action', (done) ->
      execCommand "#{sneaky} deploy -c #{config} -f async ini_a", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('Finish deploy [async]') < 0 or
           stdout.indexOf('Finish deploy [ini_a]') < 0
          return done("deploy error")
        done()

  describe 'deploy:excludes', ->
    @timeout(10000)
    it 'will exclude [node_modules, tmp] in deployment', (done) ->
      execCommand "#{sneaky} deploy -c #{config} -f async", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('--exclude=node_modules --exclude=tmp') < 0
          return done("deploy error")
        done()

  describe 'deploy:hooks', ->
    @timeout(10000)
    it 'will run hooks before/after rsync', (done) ->
      execCommand "#{sneaky} deploy -c #{configHook} -f", (err, stdout, stderr) ->
        return done(err) if err?
        if stdout.indexOf('LICENSE') < 0
          return done('deploy error')
        done()
