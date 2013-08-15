option '-c', '--config [config]', 'define the config file path, default is ~/.sneakyrc'
option '-f', '--force', 'successfully deployed repos will not be deployed twice unless use `-f`'

task 'deploy', 'deploy source code to your servers', (options) ->
  require('./deploy')(options)

task 'serv', 'start a server collect remote servers infomation', (options) ->
  require('./server').serv()