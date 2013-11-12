fs = require('fs')
ini = require('ini')

describe 'ini#parse', ->
  describe 'read:ini', ->
    it 'deploy with the following configs', (done) ->
      fs.readFile "#{__dirname}/config.ini", (err, content) ->
        return done(err) if err?
        configs = ini.parse(content.toString())
        console.log ''
        console.log configs
        done()
