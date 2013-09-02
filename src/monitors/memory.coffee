class MemoryMonitor

  monitor: (callback) ->
    callback(null, {
      total: os.totalmem()
      free: os.freemem()
      })

module.exports = MemoryMonitor
