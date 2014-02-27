http = require('http')
path = require('path')
fs = require 'fs'

taiji = express = require('taiji') # assign to express for anyone who need to use express stuffs.
flash = require('connect-flash')
mongoose = require('mongoose')
mongoStore = require('connect-mongo')(express)
passport = require('passport')

app = exports = module.exports = taiji()

app.use(express.favicon())
app.use('/client', express['static'](devDistPath + '/client'))

app.enable('case sensitive routing')
app.set('views', devDistPath + '/views')
app.set('view engine', 'jade')

if env == 'development'
  app.set('showStackError', true)
  app.use(express.errorHandler())
  app.locals.pretty = true

app.enable("jsonp callback")
app.use(express.cookieParser())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use express.session
  secret: 'hello'
  store: new mongoStore
    db: db.connection.db,
    collection: 'sessions'

app.use(flash())
app.use(passport.initialize())
app.use(passport.session())
app.use(app.router)
