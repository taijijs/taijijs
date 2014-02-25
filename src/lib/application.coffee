mixin = require('utils-merge')
escapeHtml = require('escape-html')
Router = require('./router')
methods = require('methods')
middleware = require('./middleware/init')
query = require('./middleware/query')
debug = require('debug')('express:application')
View = require('./view')
http = require('http')

app = exports = module.exports = {}

app.init = ->
  @cache = {}
  @settings = {}
  @engines = {}
  @defaultConfiguration()

app.defaultConfiguration = ->
  @enable('x-powered-by')
  @enable('etag')
  env = process.env.NODE_ENV || 'development'
  @set('env', env)
  @set('subdomain offset', 2)

  debug('booting in %s mode', env)

  @on('mount', (parent) ->
    @request.__proto__ = parent.request
    @response.__proto__ = parent.response
    @engines.__proto__ = parent.engines
    @settings.__proto__ = parent.settings

  @locals = Object.create(null)
  @mountpath = '/'
  @locals.settings = @settings

  @set('view', View)
  @set('views', process.cwd() + '/views')
  @set('jsonp callback name', 'callback')

  if env === 'production' then @enable('view cache')

  Object.defineProperty this, 'router',
    get: -> throw new Error('\'app.router\' is deprecated!\nPlease see the 3.x to 4.x migration guide for details on how to update your app.')

app.lazyrouter = ->
  if (!@_router)
    @_router = new Router
      caseSensitive: @enabled('case sensitive routing'),
      strict: @enabled('strict routing')

    @_router.use(query())
    @_router.use(middleware.init(this))

app.handle = (req, res, done) ->
  env = @get('env')
  @_router.handle req, res, (err) ->
    if (done) then return done(err)
    if err
      if res.statusCode < 400 then res.statusCode = 500
      debug('default %s', res.statusCode)
      if err.status then res.statusCode = err.status
      msg = 
        if 'production' == env then http.STATUS_CODES[res.statusCode]
        else err.stack || err.toString()
      msg = escapeHtml(msg)

      if 'test' != env then console.error(err.stack || err.toString())
      if res.headersSent then return req.socket.destroy()
      res.setHeader('Content-Type', 'text/html')
      res.setHeader('Content-Length', Buffer.byteLength(msg))
      if 'HEAD' == req.method then return res.end()
      res.end(msg)
      return

    # 404
    debug('default 404')
    res.statusCode = 404
    res.setHeader('Content-Type', 'text/html')
    if ('HEAD' == req.method) return res.end()
    res.end('Cannot ' + escapeHtml(req.method) + ' ' + escapeHtml(req.originalUrl) + '\n')

app.use = (route, fn) ->
  mount_app

  if ('string' != typeof route) fn = route, route = '/'

  if (fn.handle && fn.set) mount_app = fn

  if (mount_app)
    debug('.use app under %s', route)
    mount_app.mountpath = route
    fn = (req, res, next) {
      orig = req.app
      mount_app.handle req, res, (err) ->
        req.__proto__ = orig.request
        res.__proto__ = orig.response
        next(err)

  @lazyrouter()
  @_router.use(route, fn)

  # mounted an app
  if (mount_app)
    mount_app.parent = this
    mount_app.emit('mount', this)

  return this

app.route = (path) ->

app.engine = (ext, fn) ->
  if ('function' != typeof fn) then throw new Error('callback function required')
  if ('.' != ext[0]) ext = '.' + ext
  @engines[ext] = fn
  return this

app.param = (name, fn) ->
  self = this
  self.lazyrouter()
  if Array.isArray(name) 
    name.forEach((key) -> self.param(key, fn)
    return this
  self._router.param(name, fn)
  return this


app.set = (setting, val) ->
  if (1 == arguments.length) then return @settings[setting]
  else
    @settings[setting] = val
    return this

app.path = -> if @parent then @parent.path() + @mountpath else ''
app.enabled = (setting) -> !!@set(setting)
app.disabled = (setting) -> !@set(setting)
app.enable = (setting) -> @set(setting, true)
app.disable = (setting) -> @set(setting, false)
methods.forEach((method) ->
  app[method] = (path) ->
    if ('get' == method && 1 == arguments.length) then return @set(path)
    @lazyrouter()

    # deprecated
    if Array.isArray(path) then console.trace('passing an array to app.VERB() is deprecated and will be removed in 4.0')
    route = @_router.route(path)
    for (i=1  i<arguments.length  ++i)
      route[method](arguments[i])
    return this


app.all = (path) ->
  @lazyrouter()
  route = @_router.route(path)
  args = arguments
  methods.forEach (method) -> for arg in args then route[method](args)
  return this

app.del = app.delete

app.render = (name, options, fn) ->
  opts = {}
  cache = @cache
  engines = @engines
  view = null

  if 'function' == typeof options then fn = options, options = {}
  mixin(opts, @locals)
  if (options._locals) then mixin(opts, options._locals)
  mixin(opts, options)
  opts.cache = if null == opts.cache then @enabled('view cache') else opts.cache
  if (opts.cache) then view = cache[name]

  if !view
    view = new (@get('view'))(name, {
      defaultEngine: @get('view engine'),
      root: @get('views'),
      engines: engines
    })

    if (!view.path)
      err = new Error('Failed to lookup view "' + name + '" in views directory "' + view.root + '"')
      err.view = view
      return fn(err)

    # prime the cache
    if (opts.cache) cache[name] = view

  try view.render(opts, fn)
  catch err then fn(err)


app.listen = ->
  server = http.createServer(this)
  server.listen.apply(server, arguments)
