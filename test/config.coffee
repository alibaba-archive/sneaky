path = require('path')
should = require('should')
{execCommand} = require('./util')
sneaky = path.join(__dirname, '../bin/sneaky')
local = process.env.local or ''
config = path.join(__dirname, "config#{local}.ini")

describe 'command#config', ->

  describe 'config:show', ->
    it 'should show json formated content of config.ini', (done) ->
      execCommand "#{sneaky} config show -c #{config}", (err, stdout, stderr) ->
        configs = JSON.parse(stdout.trim())
        configs.should.have.property('user', 'tristan')
        configs.projects.should.not.be.empty
        done()
