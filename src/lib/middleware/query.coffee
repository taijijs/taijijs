qs = require('qs')
parseUrl = require('../utils').parseUrl

module.exports = query(options) ->
  query(req, res, next) ->
    if !req.query
      req.query = if ~req.url.indexOf('?') then qs.parse(parseUrl(req).query, options) else {}
    next()
