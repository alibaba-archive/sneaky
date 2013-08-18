class Router

  @aliasRoute: (req, res, target = {}) ->
    {ctrl, method, format} = target
    format = format? or req.url.match(/\.([0-9a-z]+)$/i)?[1] or null
    params = req.REQUEST or {}
    params._data = if typeof req.params == 'object' then (v for i, v of req.params) else []
    Router.subRoute {
      ctrl: ctrl
      method: method
      params: params
      format: format
    }, (err, result) ->
      return res.send(404) if err?
      res.json(result)

  @autoRoute: (req, res) ->
    format = req.url.match(/\.([0-9a-z]+)$/i)?[1] or null
    req.params[i] = v?.replace(".#{format}", '') for i, v of req.params if format?
    {ctrl, method} = req.params
    params = req.REQUEST or {}
    params._data = if req.params[1]? and req.params[1].length > 0 then req.params[1].split('/') else []
    Router.subRoute {
      ctrl: ctrl
      method: method
      params: params
      format: format
    }, (err, result) ->
      return res.send(404) if err?
      res.json(result)

  @subRoute: (data, callback = ->) ->
    {ctrl, method, params, format} = data
    try
      $ctrl = require('./controllers')["#{ctrl}Controller"]
      return callback(404) unless $ctrl?
      toFormat = "to#{format[0].toUpperCase()}#{format[1..]}" if format?
      unless typeof $ctrl[method] == 'function' or params._data.length > 0
        params._data = [method].concat(params._data or []) if method?
        method = 'index'
      unless params._id?
        params._data?.every (val) ->
          if val?.match(/^[a-z0-9]{24}$/i)  # define id format
            params._id = val
            return false
          return true
      return $ctrl[method][toFormat].call($ctrl[method], params, callback) if format?
      return $ctrl[method].call($ctrl, params, callback)
    catch e
      console.error e.toString()
      callback(404)

  @route: (app) ->
    app.get('/:ctrl/:method?*', Router.autoRoute)

module.exports = Router