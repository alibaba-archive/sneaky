CpuMonitor = require('./cpu')
DiskMonitor = require('./disk')
MemoryMonitor = require('./memory')
MongodbMonitor = require('./mongodb')
RedisMonitor = require('./redis')

module.exports =
  CpuMonitor: CpuMonitor
  DiskMonitor: DiskMonitor
  MemoryMonitor: MemoryMonitor
  MongodbMonitor: MongodbMonitor
  RedisMonitor: RedisMonitor

  cpuMonitor: new CpuMonitor
  diskMonitor: new DiskMonitor
  memoryMonitor: new MemoryMonitor
  mongodbMonitor: new MongodbMonitor
  redisMonitor: new RedisMonitor