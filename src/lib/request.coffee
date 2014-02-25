accepts = require("accepts")
typeis = require("type-is")
http = require("http")
utils = require("./utils")
fresh = require("fresh")
parseRange = require("range-parser")
parse = utils.parseUrl

req = exports = module.exports = __proto__: http.IncomingMessage::

req.get = req.header = (name) ->
  switch name = name.toLowerCase()
    when "referer", "referrer" then @headers.referrer or @headers.referer
    else  @headers[name]

req.accepts = ->
  accept = accepts(this)
  accept.types.apply accept, arguments_

req.acceptsEncoding = req.acceptsEncodings = ->
  accept = accepts(this)
  accept.encodings.apply accept, arguments_

req.acceptsCharset = req.acceptsCharsets = ->
  accept = accepts(this)
  accept.charsets.apply accept, arguments_

req.acceptsLanguage = req.acceptsLanguages = (lang) ->
  accept = accepts(this)
  accept.languages.apply accept, arguments_

req.range = (size) ->
  range = @get("Range")
  return  unless range
  parseRange size, range

req.param = (name, defaultValue) ->
  params = @params or {}
  body = @body or {}
  query = @query or {}
  return params[name]  if null isnt params[name] and params.hasOwnProperty(name)
  return body[name]  unless null is body[name]
  return query[name]  unless null is query[name]
  defaultValue

req.is = (types) ->
  types = [].slice.call(arguments_)  unless Array.isArray(types)
  typeis this, types

req.__defineGetter__ "protocol", ->
  trustProxy = @app.get("trust proxy")
  return "https"  if @connection.encrypted
  return "http"  unless trustProxy
  proto = @get("X-Forwarded-Proto") or "http"
  proto.split(/\s*,\s*/)[0]

req.__defineGetter__ "secure", -> "https" is @protocol
req.__defineGetter__ "ip", -> @ips[0] or @connection.remoteAddress
req.__defineGetter__ "ips", ->
  trustProxy = @app.get("trust proxy")
  val = @get("X-Forwarded-For")
  (if trustProxy and val then val.split(RegExp(" *, *")) else [])
req.__defineGetter__ "auth", ->
  auth = @get("Authorization")
  return  unless auth

  # malformed
  parts = auth.split(" ")
  return  unless "basic" is parts[0].toLowerCase()
  return  unless parts[1]
  auth = parts[1]

  # credentials
  auth = new Buffer(auth, "base64").toString().match(/^([^:]*):(.*)$/)
  return  unless auth
  username: auth[1]
  password: auth[2]

req.__defineGetter__ "subdomains", ->
  offset = @app.get("subdomain offset")
  (@host or "").split(".").reverse().slice offset

req.__defineGetter__ "path", -> parse(this).pathname

req.__defineGetter__ "host", ->
  trustProxy = @app.get("trust proxy")
  host = trustProxy and @get("X-Forwarded-Host")
  host = host or @get("Host")
  return  unless host
  host.split(":")[0]

req.__defineGetter__ "fresh", ->
  method = @method
  s = @res.statusCode
  return false  if "GET" isnt method and "HEAD" isnt method
  # 2xx or 304 as per rfc2616 14.26
  return fresh(@headers, @res._headers)  if (s >= 200 and s < 300) or 304 is s
  false

req.__defineGetter__ "stale", -> not @fresh
req.__defineGetter__ "xhr", -> "xmlhttprequest" is (@get("X-Requested-With") or "").toLowerCase()
