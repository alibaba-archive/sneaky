BaseController = require('./base')

class UserController extends BaseController

  index: (params, callback) ->
    console.log 'index'
    console.log arguments
    callback(null, params)

  UserController.prototype.index.toHash = ->
    key = 'user:controller:index'
    BaseController._toHash.call(@, key, arguments)

  message: (params, callback) ->
    console.log 'message'
    console.log arguments
    callback(null, params)

module.exports = UserController