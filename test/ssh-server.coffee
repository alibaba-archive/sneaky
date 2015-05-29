fs = require 'fs'
path = require 'path'
ssh2 = require 'ssh2'
{exec} = require 'child_process'
{Server, utils} = ssh2

pubKey = utils.genPublicKey(
  utils.parseKey(
    fs.readFileSync(
      path.join __dirname, 'id_rsa.pub'
    )
  )
)

server = new Server
  privateKey: fs.readFileSync(
    path.join __dirname, 'id_rsa'
  )
, (client) ->
  console.log 'Client connected!'

  client
  .on 'authentication', (ctx) -> ctx.accept()
  .on 'ready', ->
    console.log 'Client authenticated!'
    client.on 'session', (accept, reject) ->
      session = accept()
      session.once 'exec', (accept, reject, info) ->
        console.log 'Client wants to execute: ' + info.command
        stream = accept()
        child = exec info.command
        child.stdout.pipe stream
        child.stderr.pipe stream.stderr
        stream.exit 0
  .on 'end', ->
    console.log 'Client disconnected'

server.listen 2222, '127.0.0.1', -> console.log 'Listening on port ' + this.address().port
