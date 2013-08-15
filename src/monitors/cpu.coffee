class CpuMonitor

  monitor: (callback) ->
    callback(null, os.loadavg())

module.exports = CpuMonitor