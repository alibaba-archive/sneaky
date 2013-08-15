class MemoryMonitor

  monitor: (callback) ->
    callback(null, {
      total: os.totalmem()
      free: os.totalmem()
      })

module.exports = MemoryMonitor