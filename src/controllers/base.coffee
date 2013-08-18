crypto = require('crypto')

class BaseController

  @_toHash: (key, args, callback) ->
    _callback = ->
    if typeof args[args.length - 1] == 'function'
      _callback = args[args.length - 1]
      args[args.length - 1] = callback or (err, result) ->
        mixKey = "#{key}#{JSON.stringify(args)}"
        hash = crypto.createHash('sha1').update(JSON.stringify(result)).digest('hex')
        _callback(err, hash)
    @apply(@, args)

module.exports = BaseController