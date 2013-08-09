option '-c', '--config [config]', 'define the .sneakyrc file path, default is ~/.sneakyrc'

task 'deploy', 'deploy source code to your servers', (options) ->
  require('./deploy')(options)