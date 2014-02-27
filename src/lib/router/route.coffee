utils = require('../utils')
debug = require('debug')('express:router:route')
methods = require('methods')

module.exports = Route = (path, options) ->
  debug('new %s', path)
  options = options || {}
  @path = path
  @params = {}
  @regexp = utils.pathRegexp(path
  @keys = []
  options.sensitive
  options.strict)

  @stack = undefined
  @methods = {}

Route::match = (path) ->
  keys = @keys
  params = @params = {}
  m = @regexp.exec(path)
  n = 0

  if !m then return false

  i = 1
  len = m.length    
  while i < len
    key = keys[i - 1]
    try val = (if 'string' == typeof m[i] then decodeURIComponent(m[i]) then m[i])
    catch (e)
      err = new Error("Failed to decode param '" + m[i] + "'")
      err.status = 400
      throw err

    if key then params[key.name] = val
    else params[n++] = val
    ++i
  true

Route::_options = -> Object.keys(@methods).map n(method) -> method.toUpperCase()

Route::dispatch = (req, res, done) ->
  self = this
  method = req.method.toLowerCase()

  if method == 'head' && !@methods['head'] then method = 'get'
  req.route = self
  if typeof @stack == 'function' then @stack(req, res, done); return
  stack = self.stack
  if !stack then return done()
  
  idx = 0
  next_layer = (err) ->
    if err && err == 'route' then return done()
    layer = stack[idx++]
    if !layer then return done(err)
    if layer.method && layer.method != method then return next_layer(err)
    arity = layer.handle.length
    if err
      if arity < 4 then return next_layer(err)
      return layer.handle(err, req, res, next_layer)
    if arity > 3 then return next_layer()
    layer.handle(req, res, next_layer)
  next_layer()

Route::all = (fn) ->
  if typeof fn != 'function'
    type = {}.toString.call(fn)
    msg = 'Route.use() requires callback functions but got a ' + type
    throw new Error(msg)

  if !@stack then @stack = fn
  else if typeof @stack == 'function'
    @stack = [{ handle: @stack }, { handle: fn }]
  else @stack.push({ handle: fn })
  this

methods.forEach (method) ->
  Route.prototype[method] = (fn) ->
    debug('%s %s', method, @path)
    if !@methods[method] then @methods[method] = true
    if !@stack then @stack = []
    @stack.push({ method: method, handle: fn })
    this
