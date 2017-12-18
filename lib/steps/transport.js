/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const path = require('path');

/**
 * Rsync files to remote server
 * @param  {Object} task - Task instance
 * @return {Promise}
*/
module.exports = function(task) {
  let cmd = "rsync -az --delete-after --force";

  // Add filters
  if (toString.call(task.filter) === '[object String]') {
    task.filter.split('\n').forEach(filter => cmd += ` --filter=\"${filter.trim()}\"`);
  }

  // Add source destination
  if (task.deployPath) { task.srcPath = path.join(task.srcPath, task.deployPath); }

  cmd += ` ${path.join(task.srcPath, '/')}`;

  // Add remote destination
  cmd += ` -e \"ssh -p ${task.port}\" ${task.user}@${task.host}:${task.targetPath}`;

  return task.execRemoteCmd(`cd ~/ && mkdir -p ${task.targetPath}`)

  .then(() => task.execCmd(cmd))

  .then(() => task.execRemoteCmd(`cd ${task.path}; ln -sfn ${task.targetPath} ${task.path}/current`));
};
