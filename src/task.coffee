path = require 'path'
stream = require 'stream'
{Client} = require 'ssh2'
{exec} = require 'child_process'
fs = require 'fs'
Promise = require 'bluebird'
Promise.promisifyAll fs

_steps = []

class Task

  constructor: ->
    @stdout = new stream.Transform
    @stdout._transform = (chunk, encoding, callback) -> callback null, chunk
    @stderr = new stream.Transform
    @stderr._transform = (chunk, encoding, callback) -> callback null, chunk
    @_state = 'ready'
    @_preHooks = {}
    @_postHooks = {}

  ###*
   * Execute this deploy process
   * @return {Promise} The task with the finished state
  ###
  deploy: ->
    task = this

    task.name or= path.basename process.cwd()
    task.source or= process.cwd()
    task.tmpdir or= path.join process.env.HOME, '.sneaky', task.name
    task.port or= 22

    throw new Error('No valid destination provided') unless task.path

    if task.privateKey
      $privateKey = Promise.resolve(task.privateKey)
    else
      $privateKey = fs.readFileAsync path.join process.env.HOME, '.ssh/id_rsa'
      .then (privateKey) -> task.privateKey = privateKey

    Promise.all [$privateKey]

    .then -> _steps

    .map (step) ->
      stepName = step.name
      $executor = Promise.resolve()
      {_preHooks, _postHooks} = task

      if _preHooks[name]
        $executor = $executor.then -> _preHooks[name]
        .map (fn) -> fn.call task, task

      $executor = $executor.then -> step.call task, task

      if _postHooks[name]
        $executor = $executor.then -> _postHooks[name]
        .map (fn) -> fn.call task, task

  history: ->

  rollback: (n) ->

  ###*
   * Register pre hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Array}
  ###
  pre: (stepName, fn) ->
    @_preHooks[stepName] or= []
    @_preHooks[stepName].push fn

  ###*
   * Register post hooks on step
   * @param  {String}   stepName - Name of step
   * @param  {Function} fn - Hook function
   * @return {Array}
  ###
  post: (stepName, fn) ->
    @_postHooks[stepName] or= []
    @_postHooks[stepName].push fn

  ###*
   * Execute shell on localhost
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  ###
  execCmd: (cmd) ->
    task = this
    new Promise (resolve, reject) ->
      child = exec cmd, (err, output) ->
        return reject(err) if err
        resolve output

      child.stdout.pipe task.stdout
      child.stderr.pipe task.stderr

  ###*
   * Execute shell on remote servers
   * @param  {String} cmd - Commmand string
   * @return {Promise}
  ###
  execRemoteCmd: (cmd) ->
    task = this
    @_getClient()
    .then (client) ->
      new Promise (resolve, reject) ->
        # Change directory to remote working directory
        cmd = "cd #{task.realPath} && #{cmd}" unless cmd.indexOf('cd ') is 0
        client.exec cmd, (err, stream) ->
          return reject(err) if err
          output = ''
          stream.on 'data', (data) ->
            output += data
            task.stdout.write data
          stream.stderr.pipe task.stderr
          stream.on 'close', (code, signal) ->
            return reject(new Error('Remote script exited with a non-zero code!')) if code
            resolve output

  _getClient: ->
    unless @$_client
      sshOptions =
        username: @user
        host: @host
        privateKey: @privateKey
      @$_client = new Promise (resolve, reject) ->
        client = new Client
        client
        .on 'ready', -> resolve client
        .on 'error', (err) -> reject err
        .connect sshOptions
    @$_client

  ###*
   * Register a step of deploy task
   * @param  {String} stepName [description]
   * @param  {Function} step - Execute function of step
   * @return {[type]}          [description]
  ###
  @registerStep: (stepName, step, options = {}) ->
    {before, after, position} = options  # Declear the position of step
    step.name = stepName
    _steps.push step

module.exports = Task
