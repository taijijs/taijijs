send = require('send')
utils = require('../utils')
parse = utils.parseUrl
url = require('url')

exports = module.exports = (root, options) ->
  options = options || {}
  if !root then throw new Error('static() root path required')
  redirect = false != options.redirect

  (req, res, next) ->
    if 'GET' != req.method && 'HEAD' != req.method then return next()
    originalUrl = url.parse(req.originalUrl)
    path = parse(req).pathname

    if path == '/' && originalUrl.pathname[originalUrl.pathname.length - 1] != '/' then return directory()

    directory = ->
      if !redirect then return next()
      originalUrl.pathname += '/'
      target = url.format(originalUrl)
      res.statusCode = 303
      res.setHeader('Location', target)
      res.end('Redirecting to ' + utils.escape(target))

    error = (err) ->
      if (404 == err.status) then return next()
      next(err)

    send(req, path)
      .maxage(options.maxAge || 0)
      .root(root)
      .index(options.index || 'index.html')
      .hidden(options.hidden)
      .on('error', error)
      .on('directory', directory)
      .pipe(res)

