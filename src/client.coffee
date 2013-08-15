###
sneaky clients
these clients need to be deployed on remote servers
###

CpuMonitor = require('./monitors/cpu')
MemoryMonitor = require('./monitors/memory')
DiskMonitor = require('./monitors/disk')

try
  monitors = new require("./monitors/#{name}") for i, name of ['cpu', 'memroy', 'disk']
catch e


async = require('async')

class Client

  constructor: ->
    @cpuMonitor = new CpuMonitor()
    @memoryMonitor = new MemoryMonitor()
    @diskMonitor = new DiskMonitor()

  publish: ->
    async.eachSeries

module.exports = Client