async = require('async')
path = require('path')
{execCmd} = require('../util')

module.exports = (project, options, callback = ->) ->
  prefix = project.name + '/'
  project.source or= process.cwd()

  if project.source.match(/^(http|git|ssh)/)  # remote repositories
    project.nochdir = false  # Force change directory on remote repositories
    remote = path.join(options.chdir, '.repos-' + project.name)
    cmd = """
      rm -rf #{path.join(options.chdir, prefix)} #{remote}; \\
      git clone #{project.source} #{remote}; \\
      git archive #{project.version or 'HEAD'} --prefix=#{prefix} \\
      --remote=#{remote} --format=tar | tar -xf - -C #{options.chdir}
    """
  else  # local repositories
    return callback() if project.nochdir
    cmd = """
      rm -rf #{path.join(options.chdir, prefix)}; \\
      git archive #{project.version or 'HEAD'} --prefix=#{prefix} \\
      --remote=#{project.source} --format=tar | tar -xf - -C #{options.chdir}
    """
  execCmd(cmd, callback)
