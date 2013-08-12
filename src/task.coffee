option '-c', '--config [config]', 'define the config file path, default is ~/.sneakyrc'
option '-f', '--force', 'successfully deployed repos will not be deployed twice until use `-f`'

task 'deploy', 'deploy source code to your servers', (options) ->
  require('./deploy')(options)