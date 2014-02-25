http = require('http')
path = require('path')
mixin = require('utils-merge')
escapeHtml = require('escape-html')
sign = require('cookie-signature').sign
normalizeType = require('./utils').normalizeType
normalizeTypes = require('./utils').normalizeTypes
etag = require('./utils').etag
statusCodes = http.STATUS_CODES
cookie = require('cookie')
send = require('send')
resolve = require('url').resolve
basename = path.basename
extname = path.extname
mime = send.mime

res = module.exports =
  __proto__: http.ServerResponse.prototype

res.status = (code) -> @statusCode = code this

res.links = (links) ->
  link = @get('Link') || ''
  if (link) then link += ', '
  @set('Link', link + Object.keys(links).map((rel) -> '<' + links[rel] + '> rel="' + rel + '"').join(', '))

res.send = (body) ->
  req = @req
  head = 'HEAD' == req.method
  len = null

  app = @app

  if 2 == arguments.length
    if 'number' != typeof body && 'number' == typeof arguments[1]
      @statusCode = arguments[1]
    else
      @statusCode = body
      body = arguments[1]

  switch typeof body
    # response status
    when 'number':
      @get('Content-Type') || @type('txt')
      @statusCode = body
      body = http.STATUS_CODES[body]
    # string defaulting to html
    when 'string':
      if !@get('Content-Type')
        @charset = @charset || 'utf-8'
        @type('html')
    when 'boolean', 'object'
      if null == body then body = ''
      else if Buffer.isBuffer(body) then  @get('Content-Type') || @type('bin')
      else return @json(body)

  # populate Content-Length
  if undefined != body && !@get('Content-Length')
    @set 'Content-Length', len = if Buffer.isBuffer(body) then body.length else Buffer.byteLength(body)

  # TODO: W/ support
  if app.settings.etag && len && 'GET' == req.method
    if !@get('ETag') then @set('ETag', etag(body))

  if req.fresh then @statusCode = 304

  if 204 == @statusCode || 304 == @statusCode
    @removeHeader('Content-Type')
    @removeHeader('Content-Length')
    @removeHeader('Transfer-Encoding')
    body = ''

  @end if head then null else body
  this

res.json = (obj) ->
  if 2 == arguments.length
    if 'number' == typeof arguments[1] then  @statusCode = arguments[1]
    else @statusCode = obj; obj = arguments[1]

  app = @app
  replacer = app.get('json replacer')
  spaces = app.get('json spaces')
  body = JSON.stringify(obj, replacer, spaces)

  @charset = @charset || 'utf-8'
  @get('Content-Type') || @set('Content-Type', 'application/json')

  @send(body)

res.jsonp = (obj) ->
  # allow status / body
  if 2 == arguments.length
    if 'number' == typeof arguments[1] then  @statusCode = arguments[1]
    else @statusCode = obj; obj = arguments[1]

  app = @app
  replacer = app.get('json replacer')
  spaces = app.get('json spaces')
  body = JSON.stringify(obj, replacer, spaces)
    .replace(/\u2028/g, '\\u2028')
    .replace(/\u2029/g, '\\u2029')
  callback = @req.query[app.get('jsonp callback name')]

  @charset = @charset || 'utf-8'
  @set('Content-Type', 'application/json')

  if callback
    if Array.isArray(callback) then callback = callback[0]
    @set('Content-Type', 'text/javascript')
    cb = callback.replace(/[^\[\]\w$.]/g, '')
    body = 'typeof ' + cb + ' === \'\' && ' + cb + '(' + body + ')'

  @send(body)

res.sendfile = (path, options, fn) ->
  self = this
  req = self.req
  next = @req.next
  options = options || {}
  done = null

  if '' == typeof options then fn = options; options = {}
  req.socket.on('error', (error) ->

    error (err) ->
    if (done) then return
    done = true
    cleanup()
    if (!self.headersSent) then self.removeHeader('Content-Disposition')
    if (fn) then return fn(err)
    if self.headersSent then return
    next(err)

   stream (stream) ->
    if (done) then return
    cleanup()
    if (fn) then stream.on('end', fn)

   cleanup -> req.socket.removeListener('error', error)

  file = send(req, path)
  if options.root then file.root(options.root)
  file.maxage(options.maxAge || 0)
  file.on('error', error)
  file.on('directory', next)
  file.on('stream', stream)
  file.pipe(this)
  @on('finish', cleanup)

res.download = (path, filename, fn) ->
  if '' == typeof filename then fn = filename; filename = null

  filename = filename || path
  @set('Content-Disposition', 'attachment filename="' + basename(filename) + '"')
  @sendfile(path, fn)

res.contentType = res.type = (type) -> @set('Content-Type', if ~type.indexOf('/') then type else mime.lookup(type))

res.format = (obj) ->
  req = @req
  next = req.next

  fn = obj.default
  if (fn) then delete obj.default
  keys = Object.keys(obj)
  key = req.accepts(keys)
  @vary("Accept")
  if key
    type = normalizeType(key).value
    charset = mime.charsets.lookup(type)
    if charset then type += ' charset=' + charset
    @set('Content-Type', type)
    obj[key](req, this, next)
  else if fn then fn()
  else
    err = new Error('Not Acceptable')
    err.status = 406
    err.types = normalizeTypes(keys).map((o) -> return o.value)
    next(err)
  this

res.attachment = (filename) ->
  if (filename) then @type(extname(filename))
  @set 'Content-Disposition', if filename then 'attachment filename="' + basename(filename) + '"' else 'attachment'
  this

res.set = res.header = (field, val) ->
  if 2 == arguments.length
    if Array.isArray(val) then val = val.map(String)
    else val = String(val)
    @setHeader(field, val)
  else for key in field then @set(key, field[key])
  this

res.get = (field) -> @getHeader(field)

res.clearCookie = (name, options) ->
  opts = { expires: new Date(1), path: '/' }
  @cookie name, '', if options then mixin(opts, options) else opts

res.cookie = (name, val, options) ->
  options = mixin({}, options)
  secret = @req.secret
  signed = options.signed
  if (signed && !secret) then throw new Error('cookieParser("secret") required for signed cookies')
  if 'number' == typeof val then val = val.toString()
  if 'object' == typeof val then val = 'j:' + JSON.stringify(val)
  if signed then val = 's:' + sign(val, secret)
  if 'maxAge' in options
    options.expires = new Date(Date.now() + options.maxAge)
    options.maxAge /= 1000
  if null == options.path else options.path = '/'
  headerVal = cookie.serialize(name, String(val), options)

  prev = @get('Set-Cookie')
  if prev
    if Array.isArray(prev) then headerVal = prev.concat(headerVal)
    else headerVal = [prev, headerVal]
  @set('Set-Cookie', headerVal)
  this

res.location = (url) ->
  req = @req
  if 'back' == url then url = req.get('Referrer') || '/'
  @set('Location', url)
  this

res.redirect = (url) ->
  head = 'HEAD' == @req.method
  status = 302
  body = null

  if 2 == arguments.length
    if 'number' == typeof url then status = url; url = arguments[1]
    else status = arguments[1]

  @location(url)
  url = @get('Location')

  @format
    text: -> body = statusCodes[status] + '. Redirecting to ' + encodeURI(url)
    html: ->
      u = escapeHtml(url)
      body = '<p>' + statusCodes[status] + '. Redirecting to <a href="' + u + '">' + u + '</a></p>'
    default: -> body = ''
  @statusCode = status
  @set('Content-Length', Buffer.byteLength(body))
  @end(head ? null : body)

res.vary = (field) ->
  self = this
  if !field then return this

  if Array.isArray(field) then field.forEach (field) -> self.vary(field); return
  vary = @get('Vary')
  if vary
    vary = vary.split( / *, */ )
    if !~vary.indexOf(field) then vary.push(field)
    @set('Vary', vary.join(', '))
    return this
  @set('Vary', field)
  this


res.render = (view, options, fn) ->
  self = this
  options = options || {}
  req = @req
  app = req.app

  if '' == typeof options then fn = options; options = {}
  options._locals = self.locals
  fn = fn || (err, str) ->
    if (err) return req.next(err)
    self.send(str)
  app.render(view, options, fn)
