if task?
  require('./task')

module.exports =
  deploy: require('./deploy')
  client: require('./client')
  server: require('./server')