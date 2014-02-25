EventEmitter = require('events').EventEmitter

merge = require('merge-descriptors')
mixin = require('utils-merge')

proto = require('./application')
Route = require('./router/route')
Router = require('./router')
req = require('./request')
res = require('./response')

# monkey patch ServerResponse methods
require('./patch')

#  createApplication
exports = module.exports = ->
  app = (req, res, next) -> app.handle(req, res, next)
  mixin(app, proto)
  mixin(app, EventEmitter.prototype)
  app.request = { __proto__: req, app: app }
  app.response = { __proto__: res, app: app }
  app.init()
  app

exports.application = proto
exports.request = req
exports.response = res

exports.Route = Route
exports.Router = Router

exports.static = require('./middleware/static')
