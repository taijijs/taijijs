http = require('http')
path = require('path')
express = require('express')
sockio = require './sockio'

app = exports = module.exports = express()

app.use(express.favicon())

app.use(require('connect-livereload')()) # play with tiny-lr to livereload stuffs

console.log  __dirname
#app.use('/static', express['static'](__dirname + '/static'))
publicPath = path.normalize(__dirname + '/../../../public')
console.log 'public path: '+publicPath
app.use('/static', express['static'](publicPath))
clientPath = path.normalize(__dirname + '/client')
console.log 'client path: '+clientPath
app.use('/static/client', express['static'](clientPath))

env = process.env.NODE_ENV || 'development'
if env != 'test' then app.use(express.logger('dev'))

app.enable('case sensitive routing')
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')

if env == 'development'
  app.set('showStackError', true)
  app.use(express.errorHandler())
  app.locals.pretty = true

app.enable("jsonp callback")
app.use(express.cookieParser())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use express.cookieSession({secret:'sockio'})

app.use(app.router)

app.use (err, req, res, next) ->
  if ~err.message.indexOf('not found') then return next()
  console.error(err.stack)
  res.status(500).render '500', error: err.stack

app.use (req, res, next) -> res.status(404).render '404',{url: req.originalUrl, error: 'Not found'}

app.get '/', (req, res) ->
  res.render 'index', {}

port = process.env.PORT or 3000
server = http.createServer(app)
server.listen port, -> console.log('Express is listening on port ' + port + '.')
sockio.initialize server