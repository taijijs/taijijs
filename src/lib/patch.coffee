http = require('http')
ServerResponse = http.ServerResponse

if ServerResponse::_hasConnectPatch then return

setHeader = ServerResponse::setHeader
writeHead = ServerResponse::writeHead

ServerResponse::setHeader = (field, val) ->
  key = field.toLowerCase()
  if 'content-type' == key && @charset then val += ' charset=' + @charset
  setHeader.call(this, field, val)

ServerResponse::writeHead = (statusCode, reasonPhrase, headers) ->
  if typeof reasonPhrase == 'object' then headers = reasonPhrase
  if typeof headers == 'object'
    Object.keys(headers).forEach((key) ->
      @setHeader(key, headers[key])
    , this)
  if (!@_emittedHeader) then @emit('header')
  @_emittedHeader = true
  writeHead.call(this, statusCode, reasonPhrase)

ServerResponse::_hasConnectPatch = true
