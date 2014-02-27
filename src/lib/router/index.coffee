Route = require('./route')
utils = require('../utils')
methods = require('methods')
debug = require('debug')('express:router')
parseUrl = utils.parseUrl

exports = module.exports = Router = (options) ->
  options = options || {}
  self = this
  self.params = {}
  self._params = []
  self.caseSensitive = options.caseSensitive
  self.strict = options.strict
  self.stack = []

  self.middleware = self.handle.bind(self)

Router::param = (name, fn) ->
  if 'function' == typeof name then @_params.push(name); return
  params = @_params
  len = params.length
  ret = null

  if name[0] == ':' then name = name.substr(1)

  for param in params then if (ret = param(name, fn)) then fn = ret
  if 'function' != typeof fn then throw new Error('invalid param() call for ' + name + ', got ' + fn)

  (@params[name] = @params[name] || []).push(fn)
  this

Router::handle = (req, res, done) ->
  self = this

  debug('dispatching %s %s', req.method, req.url)

  method = req.method.toLowerCase()

  search = 1 + req.url.indexOf('?')
  pathlength = if search then search - 1 else req.url.length
  fqdn = 1 + req.url.substr(0, pathlength).indexOf('://')
  protohost = if fqdn then req.url.substr(0, req.url.indexOf('/', 2 + fqdn)) else ''
  idx = 0
  removed = ''
  slashAdded = false
  options = []
  stack = @stack
  if method == 'options'
    old = done
    done = (err) ->
      if err || options.length == 0 then return old(err)
      body = options.join(',')
      res.set('Allow', body).send(body)

  next = (err) ->
    if err == 'route'then err = undefined
    layer = stack[idx++]
    if !layer then return done(err)
    if slashAdded then req.url = req.url.substr(1); slashAdded = false

    req.url = protohost + removed + req.url.substr(protohost.length)
    req.originalUrl = req.originalUrl || req.url
    removed = ''

    try
      path = parseUrl(req).pathname
      if undefined == path then path = '/'
      route = layer.route
      if route
        if err || !route.match(path) then return next(err)
        req.params = route.params
        if method == 'options' && !route.methods['options']
          options.push.apply(options, route._options())
        return self.process_params route, req, res, (err) ->
          if err then return next(err)
          route.dispatch(req, res, next)

      if 0 != path.toLowerCase().indexOf(layer.path.toLowerCase()) then return next(err)

      c = path[layer.path.length]
      if c && '/' != c && '.' != c then return next(err)

      debug('trim prefix (%s) from url %s', removed, req.url)
      removed = layer.path
      req.url = protohost + req.url.substr(protohost.length + removed.length)

      if !fqdn && '/' != req.url[0] then req.url = '/' + req.url; slashAdded = true

      debug('%s %s : %s', layer.handle.name || 'anonymous', layer.path, req.originalUrl)
      arity = layer.handle.length
      if err
        if arity == 4 then layer.handle(err, req, res, next)
        else next(err)
      else if arity < 4 then layer.handle(req, res, next)
      else next(err)
    catch err then next(err)
  next()

Router::process_params = (route, req, res, done) ->
  self = this
  params = @params
  keys = route.keys || []

  i = 0
  paramIndex = 0
  key = paramVal = paramCallbacks = null

  param = (err) ->
    if err then return done(err)
    if i >= keys.length then return done()
    paramIndex = 0
    key = keys[i++]
    paramVal = key && req.params[key.name]
    paramCallbacks = key && params[key.name]
    try
      if paramCallbacks && undefined != paramVal then return paramCallback()
      else if key then return param()
    catch err then done(err)
    done()

  paramCallback = (err) ->
    fn = paramCallbacks[paramIndex++]
    if err || !fn then return param(err)
    fn(req, res, paramCallback, paramVal, key.name)
  param()

Router::use = (route, fn) ->
  if 'string' != typeof route then fn = route; route = '/'
  if '/' == route[route.length - 1] then route = route.slice(0, -1)
  debug('use %s %s', route || '/', fn.name || 'anonymous')
  @stack.push({ path: route, handle: fn })
  this

Router::route = (path) ->
  route = new Route path,
    sensitive: @caseSensitive,
    strict: @strict
  @stack.push({ path: path, route: route })
  route

Router::all = (path, fn) ->
  route = @route(path)
  methods.forEach (method) -> route[method](fn)

methods.forEach (method) ->
  Router.prototype[method] = (path, fn) ->
    self = this
    self.route(path)[method](fn)
    self