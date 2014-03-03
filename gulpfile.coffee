gulp = require('gulp')
gutil = require 'gulp-util'
changed = require('gulp-changed')
cache = require('gulp-cached')
plumber = require('gulp-plumber')
clean = require('gulp-clean')
shell = require 'gulp-shell'
coffee = require ('gulp-coffee')
mocha = require('gulp-mocha')
karma = require('gulp-karma')

#pluginwatch = require('gulp-watch')

#browserify = require('gulp-browserify')
#concat = require('gulp-concat')
#styl = require('gulp-styl')

express = require('express')

#http://rhumaric.com/2014/01/livereload-magic-gulp-style/
livereload = require('gulp-livereload')
tinylr = require('tiny-lr')
tinylrServer = tinylr()
tinylrServer.listen(35729)

task = gulp.task.bind(gulp)
watch = gulp.watch.bind(gulp)
src = gulp.src.bind(gulp)
dest = gulp.dest.bind(gulp)
from = (source, options={dest:'dist', cache:'cache'}) ->
  options.dest ?= 'dist'
  options.cache ?= 'cache'
  src(source).pipe(changed(options.dest)).pipe(cache(options.cache)).pipe(plumber())
GulpStream = src('').constructor
GulpStream::to = (dst) -> @pipe(dest(dst)).pipe(livereload(tinylrServer))
GulpStream::pipelog = (obj, log=gutil.log) -> @pipe(obj).on('error', log)

paths =
  copy: ('src/'+name for name in ['**/*.js', '**/*.json', '**/*.jade', '**/*.html', '**/*.css', '**/*.tjv'])
  coffee: 'src/**/*.coffee'
  mocha: 'dist/test/mocha/**/*.js'
  karma: 'dist/test/karma/**/*.js'
  modulejs: 'dist/lib/modules/**/*.js'
  serverjs: 'dist/lib/server/**/*.js'
  reload: ['*.html', 'dist/client/**/*.js', 'dist/modules/**/*.js', 'public/**/*.js', 'public/**/*.css']

task 'clean', -> src(['dist'], {read:false}) .pipe(clean())
task 'runapp', shell.task ['node dist/examples/sockio/app.js']
task 'express',  ->
  app = express()
  app.use(require('connect-livereload')()) # play with tiny-lr to livereload stuffs
  console.log __dirname
  app.use(express.static(__dirname))
  app.listen(4000)
task 'copy', -> from(paths.copy, {cache:'copy'}).to('dist')
task 'coffee', -> from(paths.coffee, {cache:'coffee'}).pipelog(coffee({bare: true})).to('dist')
onErrorContinue = (err) -> console.log(err.stack); @emit 'end'
#onErrorContinue = (err) -> @emit 'end'
task 'mocha', ->
  src(paths.mocha)
#  .pipelog(plumber())
  .pipe(mocha({reporter: 'dot'})).on("error", onErrorContinue)
task 'karma', -> src(paths.karma).pipe(karma({configFile: 'dist/test/karma-conf', action: 'run'}))     # run: once, watch: autoWatch=true
task 'stylus', -> from(['css/**/*.css']).pipe(styl({compress: true})).to('dist')
task 'lr-server', -> server.listen 35729, (err) -> if err then console.log(err)
task 'watch:copy', -> watch paths.copy, ['copy']
onWatchReload = (event) -> src(event.path, {read: false}).pipe(livereload(tinylrServer))
task 'watch:reload', -> watch paths.reload,onWatchReload
task 'watch:coffee', -> watch paths.coffee, ['coffee']
task 'watch:mocha', -> watch [paths.modulejs, paths.serverjs, paths.mocha], ['mocha']
#task 'watch:mocha', ->
#  src([paths.modulejs, paths.serverjs, paths.mocha])
#  .pipe(plumber())
#  .pipe pluginwatch emit: 'all', (files) ->
#    files.pipe(mocha(reporter: 'dot' ))
#    .on 'error', onErrorContinue
task 'watch:all', -> ['watch:copy', 'watch:coffee', 'watch:mocha', 'watch:reload']
task 'build', ['copy', 'coffee']
task 'mocha:auto', ['watch:copy', 'watch:coffee', 'watch:mocha']
task 'default',['build', 'watch:all']

