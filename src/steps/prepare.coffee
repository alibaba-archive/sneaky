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

  # Do not change directory
  process.chdir sourceDir
  if task.nochdir
    $rsyncSource = Promise.resolve(task.source)
  else
    # Cleanup the tmp directory first
    $mkTmpDir = rimrafAsync task.tmpdir
    .then -> mkdirpAsync task.tmpdir

    rsyncSource = path.join task.tmpdir, 'deploy'

    if /^(http|git|ssh)/.test task.source  # Remote repositories
      sourceRepos = path.join task.tmpdir, 'git-cache'
      $sourceRepos = $mkTmpDir
      .then -> task.execCmd "git clone #{task.source} #{sourceRepos}"
      .then -> process.chdir sourceRepos

    else $sourceRepos = Promise.resolve(task.source)

    # Prepare source path
    $rsyncSource = $sourceRepos
    .then (sourceRepos) ->
      task.execCmd "git archive #{task.version} --remote=#{sourceRepos} --format=tar.gz | tar -xzf - -C #{rsyncSource}"
      rsyncSource

  $rsyncSource = $rsyncSource.then (rsyncSource) -> task.rsyncSource = rsyncSource

  $realPath = $rsyncSource
  .then -> task.execCmd "git rev-list #{task.version} | head -n 1"
  .then (revHash) ->
    # Set the real path of destination
    task.realPath = path.join talk.path, moment().format('YYYYMMDDHHmmss') + '-' + revHash.trim()[...8]

  $chdir = Promise.all [$realPath, $rsyncSource]
  .then ([realPath, rsyncSource]) -> process.chdir rsyncSource
