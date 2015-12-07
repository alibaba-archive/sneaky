path = require 'path'
Promise = require 'bluebird'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
mkdirpAsync = Promise.promisify mkdirp
rimrafAsync = Promise.promisify rimraf
moment = require 'moment'

###*
 * Prepare for the working directory of deployment
 * @param  {Object} task - Task instance
 * @return {Promise}
###
module.exports = (task) ->
  # Do not archive the git repository to tmp directory when nochdir flag is checked
  task.source or= process.cwd()
  task.version or= 'HEAD'

  tmpdir = path.join process.env.HOME, '.sneaky', "#{Date.now()}"

  # Do not change directory
  process.chdir task.source
  if task.nochdir
    $srcPath = Promise.resolve(task.source)
  else
    srcPath = path.join tmpdir, 'deploy'
    # Cleanup the tmp directory first
    $mkTmpDir = rimrafAsync tmpdir
    .then -> mkdirpAsync tmpdir
    .then -> mkdirpAsync srcPath

    if /^(http|git|ssh)/.test task.source  # Remote repositories
      sourceRepos = path.join tmpdir, 'git-cache'
      $sourceRepos = $mkTmpDir
      .then -> task.execCmd "git clone #{task.source} #{sourceRepos}"
      .then -> process.chdir sourceRepos

    else $sourceRepos = $mkTmpDir.then -> task.source

    # Prepare source path
    $srcPath = $sourceRepos
    .then (sourceRepos) ->
      task.execCmd "git archive #{task.version} --remote=#{sourceRepos} --format=tar.gz | tar -xzf - -C #{srcPath}"
      .then -> srcPath

  $srcPath = $srcPath.then (srcPath) -> task.srcPath = srcPath

  if task.overwrite
    # Do not create new directories for each deployment
    $targetPath = Promise.resolve()
    .then -> task.targetPath = targetPath = path.join task.path, 'source'
  else
    $targetPath = $srcPath
    .then -> task.execCmd "git log #{task.version} --decorate --oneline | head -n 1"
    .then (log) ->
      matches = log.match /([0-9a-z]{7})\ (\((.*)\) )?/i
      commit = matches[1]
      decorate = matches[3]
      version = false
      decorate?.split ','
      .some (dec) -> version = dec.split(':')[1].trim() if dec.trim().indexOf('tag') is 0
      version or= commit
      # Create directory of target path
      task.targetPath = targetPath = path.join task.path, moment().format('YYYYMMDDHHmmss') + '-' + version

  $chdir = Promise.all [$targetPath, $srcPath]
  .then ([targetPath, srcPath]) -> process.chdir srcPath
