should = require('should')
path = require('path')
{exec} = require('child_process')
sneaky = path.join(__dirname, '../bin/sneaky')
config = path.join(__dirname, 'config.ini')

describe 'command#deploy', ->
  describe 'deploy:allProjects', ->
    @timeout(30000)

    it 'should deploy all projects from the config file', (done) ->
      console.log ''
      child = exec "#{sneaky} deploy -c #{config}", (err, stdout, stderr) ->
        return done(err) if err?
        done()

      child.stdout.on 'data', (data) ->
        process.stdout.write(data)

      child.stderr.on 'data', (data) ->
        process.stdout.write(data)
