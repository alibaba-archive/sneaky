path = require 'path'
stream = require 'stream'
{exec, spawn} = require 'child_process'
fs = require 'fs'
logger = require 'graceful-logger'
moment = require 'moment'
Promise = require 'bluebird'
Promise.promisifyAll fs

class Task

  constructor: ->
    @_preHooks = {}
    @_postHooks = {}
    @_steps = [
      stepName: 'prepare'
      executor: require './steps/prepare'
    ,
      stepName: 'transport'
      executor: require './steps/transport'
    ]
    @stdout = new stream.Transform
    @stdout._transform = (chunk, encoding, callback) -> callback null, chunk
    @stderr = new stream.Transform
    @stderr._transform = (chunk, encoding, callback) -> callback null, chunk

  initialize: ->
    task = this
    task.appName or= task.taskName.split(':')[0]
    task.taskName or= path.basename process.cwd()
    task.source or= process.cwd()
    task.tmpdir or= path.join process.env.HOME, '.sneaky', task.appName
    task.port or= 22
    throw new Error("Task #{task.taskName}'s path is undefined") unless task.path

  ###*
   * Execute this deploy process
   * @return {Promise} The task with the finishd state
  ###
  deploy: ->
    task = this

    logger.info "start deploy #{task.taskName}"

    Promise.resolve()

    .then -> task._steps

    .each (step) ->
      {stepName, executor} = step
      $executor = Promise.resolve()
      {_preHooks, _postHooks} = task

      if _preHooks[stepName]
        $executor = $executor.then -> _preHooks[stepName]
        .each (fn) -> fn.call task, task

      $executor = $executor.then -> executor.call task, task

      if _postHooks[stepName]
        $executor = $executor.then -> _postHooks[stepName]
        .each (fn) -> fn.call task, task

      $executor

    .then -> logger.info "finish deploy #{task.taskName}"

  history: ->
    task = this
    Promise.resolve()
    .then ->
      sshCmd = task._wrapRemoteCmd "cd #{task.path}; ls -ltr | tail -n 30"
      new Promise (resolve, reject) ->
        child = exec sshCmd, (err, out) ->
          return reject(err) if err
          resolve out

    .then (out) ->
      current = ''
      histories = out.split '\n'
      .map (line) ->
        if /current/.test line
          current = path.basename(line).trim()
        else if matches = line.match /\d{14}\-.*/i
          return matches[0].trim()
        false
      .filter (history) -> history
      .map (history) ->
        [date, commit] = history.split '-'
        m = moment date, 'YYYYMMDDHHmmss'

        date: m.format('YYYY-MM-DD HH:mm:ss')
        commit: commit
        current: if current is history then true else false
        dirname: history
        path: path.join task.path, history

  rollback: (n = 1) ->
    task = this

    version = n if isNaN(Number(n))  # Rollback to the specific version

    logger.info "start rollback #{task.taskName} to version #{version or n}"

    task.history()

    .then (histories) ->

      beforeCurrent = false
      chosenHistory = false
      diffNum = 0
      histories.reverse()
      .some (history) ->
        # Do not checkout the version after current
        beforeCurrent = true if history.current
        return unless beforeCurrent
        if version
          if commit is version
            chosenHistory = history
            return true
        else
          if n is 0
            chosenHistory = history
            return true
          # Skip this version
          n -= 1
        return false

      throw new Error("Can not find the rollback version") unless chosenHistory

      cmd = "cd #{task.path}; ln -sfn #{chosenHistory.path} #{path.join task.path, 'current'}"
      task.execRemoteCmd cmd
      .then -> task.targetPath = chosenHistory.path

    .then ->
      # Execute the hooks after transport
      if task._postHooks?.transport?.length
        return Promise.resolve task._postHooks.transport
        .each (fn) -> fn.call task, task

  ###*
   * Register pre hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Promise}
  ###
  pre: (stepName, fn) ->
    @_preHooks[stepName] or= []
    @_preHooks[stepName].push fn

  ###*
   * Register post hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Function}
  ###
  post: (stepName, fn) ->
    @_postHooks[stepName] or= []
    @_postHooks[stepName].push fn

  ###*
   * Execute script before transport
   * It is an alias function of `execCmd` before `transport` step
   * @param  {String} stepName - Name of step
   * @param  {String|Function} script - Script string or function
   * @return {Function}
  ###
  before: (stepName, script) ->
    if arguments.length is 1
      script = stepName
      stepName = 'transport'
    if toString.call(script) is '[object Function]'
      fn = script
    else
      fn = => @execCmd script
    @pre stepName, fn

  ###*
   * Execute remote script after transport and linking to the new directory
   * It is an alias function of `execRemoteCmd` after `transport` step
   * @param  {String} stepName - Name of step
   * @param  {String|Function} script - Script string or function
   * @return {Function}
  ###
  after: (stepName, script) ->
    if arguments.length is 1
      script = stepName
      stepName = 'transport'
    if toString.call(script) is '[object Function]'
      fn = script
    else
      fn = => @execRemoteCmd script
    @post stepName, fn

  _execCmd: (cmd) ->
    task = this
    new Promise (resolve, reject) ->
      child = exec cmd, (err, out) ->
        return reject(err) if err
        resolve(out)
      child.stdout.on 'data', (data) -> task.stdout.write data
      child.stderr.on 'data', (data) -> task.stderr.write data

  _wrapRemoteCmd: (cmd) ->
    task = this
    # Change directory to remote working directory
    cmd = "cd #{task.targetPath} && #{cmd}" unless cmd.indexOf('cd ') is 0
    sshCmd = "ssh"
    sshCmd += " -p #{task.port}" if task.port
    sshCmd += " -i #{task.key}" if task.key
    sshCmd += " #{task.user}@#{task.host}"
    sshCmd += " \"#{cmd}\""
    sshCmd

  ###*
   * Execute shell on localhost
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  ###
  execCmd: (cmd) ->
    logger.info cmd
    @_execCmd cmd

  ###*
   * Execute shell on remote servers
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  ###
  execRemoteCmd: (cmd) ->
    sshCmd = @_wrapRemoteCmd cmd
    logger.info sshCmd
    @_execCmd sshCmd

module.exports = Task
