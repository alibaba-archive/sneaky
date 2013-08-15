{exec} = require('child_process')

class DiskMonitor

  monitor: (callback) ->
    exec('df -k', callback)

module.exports = DiskMonitor