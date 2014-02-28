copyDevFiles = copyFiles = [
  ['src/', 'dist/',['**/*.js', '**/*.json', '**/*.jade', '**/*.html', '**/*.css', '**/*.tjv']]
]

coffeeFolders = ['**/']
coffeePatterns = ('src/'+folder+'*.coffee' for folder in coffeeFolders)

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    shell:  # grunt-shell or grunt-shell-spawn.
      options: stdout: true
      runapp: command: 'node dist/examples/sockio/server/app.js'
    clean: {dist: 'dist'}
    copy:
      dev: files:
        for item in copyDevFiles then {expand: true, dot: true, cwd: item[0], dest: item[1], src: item[2]}

    coffee:
        options: {sourceRoot: '', bare: true} # sourceMap: true
        dev: files: for folder in coffeeFolders
            {expand: true, cwd: 'src', src: folder+'*.coffee', dest:'dist', ext:'.js'}

    mochaTest: # server side
      all:
        options: reporter: 'dot'
        src: ['dist/test/mocha/**/test*.js']

  watchConfig =
    dev:
      options:{spawn: false, debounceDelay: 100}
      copy:
        files: ['src/**/*.js']
        tasks: ['copy:dev']
      coffee:{files: coffeePatterns, tasks: ['coffee:dev']}
      runapp:
        options: {livereload: 1337, debounceDelay: 500}
        files: ['src/**/*.coffee',
                'src/**/*.scss', 'src/**/*.css', 'src/**/*.jade'
        ]
        taskes: ['shell:runapp']

    mocha: # watch mochaTest
      options:{spawn: true}
      mochaTest:
        files: ['dist/**/*.js']
        tasks: ['mochaTest']

  grunt.option 'force', true
  for task in ['grunt-contrib-clean',  'grunt-contrib-copy', 'grunt-shell',
      'grunt-contrib-coffee', 'grunt-mocha-test', 'grunt-contrib-watch']
    grunt.loadNpmTasks(task)
  grunt.registerTask 'look', 'dynamic watch', ->
    target = grunt.task.current.args[0] or 'dev'
    grunt.config.set('watch', watchConfig[target])
    grunt.task.run 'watch'
    if target=='dev'
      grunt.event.on 'watch', (action, filepath) ->
        if action=='deleted' then return
        if grunt.file.isMatch coffeePatterns, [filepath]
          grunt.config.set 'coffee',
            options: {sourceRoot: '', bare: true} # , sourceMap: true
            dev: {expand: true, cwd: 'src', dest: 'dev', src: filepath.slice(4), ext: '.js'}

  grunt.registerTask('builddev', ['clean:dist', 'coffee:dev', 'copy:dev'])  # builddev have include all tasks related to tests
  grunt.registerTask('build', ['builddev'])
  grunt.registerTask('dev', ['builddev'])
  grunt.registerTask('mocha1', ['mochaTest'])
  grunt.registerTask('mocha', ['mochaTest', 'look:mocha'])
  grunt.registerTask('once', ['mochaTest'])
  grunt.registerTask('unit1', ['mochaTest'])
  grunt.registerTask('unit', ['unit1'])
  grunt.registerTask('test', ['unit'])
  grunt.registerTask('default', ['dev'])