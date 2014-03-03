path = require('path')
{execCmd} = require('../util')

module.exports = (project, options, callback = ->) ->
  prefix = project.name + '/'
  project.source or= process.cwd()
  cmd = """
    rm -rf #{path.join(options.chdir, prefix)}; \\
    git archive #{project.version or 'HEAD'} --prefix=#{prefix} \\
    --remote=#{project.source} --format=tar | tar -xf - -C #{options.chdir}
  """
  execCmd(cmd, callback)
