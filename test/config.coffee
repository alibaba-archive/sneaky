path = require('path')
should = require('should')
{execCommand} = require('./util')
sneaky = path.join(__dirname, '../bin/sneaky')
config = path.join(__dirname, 'configs', "config.ini")

describe 'command#config', ->

  describe 'config:show', ->
    it 'should show json formated content of config.ini', (done) ->
      execCommand "#{sneaky} config show -c #{config}", (err, stdout, stderr) ->
        configs = JSON.parse(stdout.trim())
        configs.projects.should.not.be.empty
        done()
