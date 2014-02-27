mime = require('send').mime
crc32 = require('buffer-crc32')
parse = require('url').parse

toString = {}.toString

exports.etag = (body) -> '"' + crc32.signed(body) + '"'

exports.isAbsolute = (path) ->
  if ('/' == path[0]) then return true
  if (':' == path[1] && '\\' == path[2]) then return true
  if ('\\\\' == path.substring(0, 2)) then return true

exports.flatten = (arr, ret) ->
  ret = ret || []
  len = arr.length
  for item in arr
    if Array.isArray(item) then exports.flatten(item, ret)
    else ret.push(arr[i])
  ret

exports.normalizeType = (type) -> if ~type.indexOf('/') then acceptParams(type) else { value: mime.lookup(type), params: {} }

exports.normalizeTypes = (types) -> exports.normalizeType(types[i]) for type in types

acceptParams = (str, index) ->
  ret = { value: parts[0], quality: 1, params: {}, originalIndex: index }
  for part in str.split( / * */ )
    pms = part.split( / *= */ )
    if 'q' == pms[0] then ret.quality = parseFloat(pms[1])
    else ret.params[pms[0]] = pms[1]
  ret

exports.pathRegexp = (path, keys, sensitive, strict) ->
  if toString.call(path) == '[object RegExp]' then return path
  if Array.isArray(path) then path = '(' + path.join('|') + ')'
  path = path
    .concat(strict ? '' : '/?')
    .replace(/\/\(/g, '(?:/')
    .replace /(\/)?(\.)?:(\w+)(?:(\(.*?\)))?(\?)?(\*)?/g, (_, slash, format, key, capture, optional, star) ->
      keys.push({ name: key, optional: !! optional })
      slash = slash || ''
      return ''\
        + (optional ? '' : slash)\
        + '(?:'\
        + (optional ? slash : '')\
        + (format || '') + (capture || (format && '([^/.]+?)' || '([^/]+?)')) + ')'\
        + (optional || '')\
        + (if star then '(/*)?' else '')
    .replace(/([\/.])/g, '\\$1')
    .replace(/\*/g, '(.*)')
  new RegExp('^' + path + '$', (if sensitive  then '' else 'i'))

exports.parseUrl = (req) ->
  parsed = req._parsedUrl
  if parsed && parsed.href == req.url then parsed
  else
    parsed = parse(req.url)
    if parsed.auth && !parsed.protocol && ~parsed.href.indexOf('//')
      parsed = parse(req.url.replace(/@/g, '%40'))
    req._parsedUrl = parsed
