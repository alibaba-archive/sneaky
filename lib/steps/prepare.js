/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const path = require('path');
const Promise = require('bluebird');
const mkdirp = require('mkdirp');
const rimraf = require('rimraf');
const mkdirpAsync = Promise.promisify(mkdirp);
const rimrafAsync = Promise.promisify(rimraf);
const moment = require('moment');

/**
 * Prepare for the working directory of deployment
 * @param  {Object} task - Task instance
 * @return {Promise}
*/
module.exports = function(task) {
  // Do not archive the git repository to tmp directory when nochdir flag is checked
  let $chdir, $srcPath, $targetPath;
  if (!task.source) { task.source = process.cwd(); }
  if (!task.version) { task.version = 'HEAD'; }

  const tmpdir = path.join(process.env.HOME, '.sneaky', `${Date.now()}`);

  // Do not change directory
  process.chdir(task.source);
  if (task.nochdir) {
    $srcPath = Promise.resolve(task.source);
  } else {
    let $sourceRepos;
    const srcPath = path.join(tmpdir, 'deploy');
    // Cleanup the tmp directory first
    const $mkTmpDir = rimrafAsync(tmpdir)
    .then(() => mkdirpAsync(tmpdir))
    .then(() => mkdirpAsync(srcPath));

    if (/^(http|git|ssh)/.test(task.source)) {  // Remote repositories
      const sourceRepos = path.join(tmpdir, 'git-cache');
      $sourceRepos = $mkTmpDir
      .then(() => task.execCmd(`git clone ${task.source} ${sourceRepos}`))
      .then(() => process.chdir(sourceRepos));

    } else { $sourceRepos = $mkTmpDir.then(() => task.source); }

    // Prepare source path
    $srcPath = $sourceRepos
    .then(sourceRepos =>
      task.execCmd(`git archive ${task.version} --remote=${sourceRepos} --format=tar.gz | tar -xzf - -C ${srcPath}`)
      .then(() => srcPath)
    );
  }

  $srcPath = $srcPath.then(srcPath => task.srcPath = srcPath);

  if (task.overwrite) {
    // Do not create new directories for each deployment
    $targetPath = Promise.resolve()
    .then(function() { let targetPath;
    return task.targetPath = (targetPath = path.join(task.path, 'source')); });
  } else {
    $targetPath = $srcPath
    .then(() => task.execCmd(`git log ${task.version} --decorate --oneline | head -n 1`))
    .then(function(log) {
      let targetPath;
      const matches = log.match(/([0-9a-z]{7})\ (\((.*)\) )?/i);
      const commit = matches[1];
      const decorate = matches[3];
      let version = false;
      if (decorate != null) {
        decorate.split(',')
      .some(function(dec) { if (dec.trim().indexOf('tag') === 0) { return version = dec.split(':')[1].trim(); } });
      }
      if (!version) { version = commit; }
      // Create directory of target path
      return task.targetPath = (targetPath = path.join(task.path, moment().format('YYYYMMDDHHmmss') + '-' + version));
    });
  }

  return $chdir = Promise.all([$targetPath, $srcPath])
  .then(function(...args) { let targetPath;
  let srcPath; [targetPath, srcPath] = Array.from(args[0]); return process.chdir(srcPath); });
};
