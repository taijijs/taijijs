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

#browserify = require('gulp-browserify')
#concat = require('gulp-concat')
#styl = require('gulp-styl')

express = require('express')

#http://rhumaric.com/2014/01/livereload-magic-gulp-style/
refresh = require('gulp-livereload')
tinylr = require('tiny-lr')
tinylrServer = tinylr()
tinylrServer.listen(35729)

paths =
  copy: ('src/'+name for name in ['**/*.js', '**/*.json', '**/*.jade', '**/*.html', '**/*.css', '**/*.tjv'])
  coffee: 'src/**/*.coffee'
  mocha: 'dist/test/mocha/**/*.js'
  karma: 'dist/test/karma/**/*.js'

gulp.task 'clean', ->
  gulp.src(['dist'], {read:false})
  .pipe(clean())

gulp.task 'runapp', shell.task ['node dist/examples/sockio/app.js']

gulp.task 'express',  ->
  app = express()
  app.use(require('connect-livereload')()) # play with tiny-lr to livereload stuffs
  console.log __dirname
  app.use(express.static(__dirname))
  app.listen(4000)

gulp.task 'copy', ->
  gulp.src(paths.copy)
  .pipe(gulp.dest('dist'))

gulp.task 'coffee', ->
  gulp.src(paths.coffee)
  .pipe(changed('dist'))
  .pipe(cache('coffee'))
  .pipe(plumber())
  .pipe(coffee({bare: true}).on('error', gutil.log))
  .pipe(gulp.dest('dist'))
  .pipe(refresh(tinylrServer))

gulp.task 'mocha', ->
  gulp.src(paths.mocha)
  .pipe(mocha({reporter: 'dot'}))

gulp.task 'karma', ->
  gulp.src(paths.karma)
  .pipe(karma({configFile: 'dist/test/karma-conf', action: 'run'}))     # run: once, watch: autoWatch=true

#gulp.task 'scripts', ->
#  gulp.src(['src/**/*.js'])
#  .pipe(browserify())
#  .pipe(concat('dest.js'))
#  .pipe(gulp.dest('build'))
#  .pipe(refresh(tinylrServer))
#
#gulp.task 'styles', ->
#  gulp.src(['css/**/*.css'])
#  .pipe(styl({compress: true}))
#  .pipe(gulp.dest('build'))
#  .pipe(refresh(tinylrServer))
#
gulp.task 'lr-server', ->
  server.listen 35729, (err) ->
    if err then console.log(err)

gulp.task 'watch', ->
  gulp.watch paths.copy , ['copy']
  gulp.watch  paths.coffee, ['coffee']
  gulp.watch paths.mocha, ['mocha']
  gulp.watch '*.html', (event) ->
    gulp.src(event.path, {read: false})
    .pipe(refresh(tinylrServer))

gulp.task 'build', ['copy', 'coffee']
gulp.task 'default',['build', 'watch']
gulp.task 'watchapp', ['express', 'watch']