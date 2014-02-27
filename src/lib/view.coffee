path = require('path')
fs = require('fs')
utils = require('./utils')
dirname = path.dirname
basename = path.basename
extname = path.extname
exists = fs.existsSync || path.existsSync
join = path.join

module.exports = View = (name, options) ->
  options = options || {}
  @name = name
  @root = options.root
  engines = options.engines
  @defaultEngine = options.defaultEngine
  ext = @ext = extname(name)
  if !ext && !@defaultEngine then throw new Error('No default engine was specified and no extension was provided.')
  if !ext then name += (ext = @ext = ('.' != @defaultEngine[0] ? '.' : '') + @defaultEngine)
  @engine = engines[ext] || (engines[ext] = require(ext.slice(1)).__express)
  @path = @lookup(name)

View::lookup = (path) ->
  ext = @ext
  if !utils.isAbsolute(path) then path = join(@root, path)
  if exists(path) then return path
  path = join(dirname(path), basename(path, ext), 'index' + ext)
  if (exists(path)) then return path

View::render = (options, fn) -> @engine(@path, options, fn)