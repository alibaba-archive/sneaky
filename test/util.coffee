{exec} = require('child_process')

exports.execCommand = (cmd, callback = ->) ->
  console.log ''

  child = exec(cmd, callback)

  child.stdout.on 'data', (data) -> process.stdout.write(data)
  child.stderr.on 'data', (data) -> process.stderr.write(data)
