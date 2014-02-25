workdir = 'dev'
copyDevFiles = [
  ['src/styles', 'dev/public/css', ['**/*.css']],
  ['src/views', 'dev/views', ['**/*.jade', '**/*.html']],
  ['src/server', 'dev/server',['**/*.js', '**/*.json']],
  ['src/client', 'dev/client',['**/*.json']],
  ['src/modules', 'dev/modules',['**/*.js', '**/*.json']]
]

copyTestFiles = [
  ['src/test', 'dev/test', ['**/*.html', '**/*.css', '**/*.js', '**/*.json']]
]

copyDevFiles = copyDevFiles.concat copyTestFiles
coffeeFolders = ['server/**/', 'modules/**/', 'deprecated/**/', 'test/', 'test/mocha-server/**/', 'client/**/',
                 'test/karma/**/', 'test/protractor/**/', 'test/', 'test/mocha-server/**/']
coffeePatterns = ('src'+'/'+folder+'*.coffee' for folder in coffeeFolders)

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    clean: {dev: 'dev', test: 'dev/test'}
    shell:  # grunt-shell or grunt-shell-spawn.
      options: stdout: true
      runapp: command: 'node '+workdir+'/server/app.js'
      # grunt-protractor-runner masks the global var element, by, and browser, use this instead.
      protractor: command: 'protractor dev/test/protractor-conf.js'
    copy:
      dev: files:
        for item in copyDevFiles then {expand: true, dot: true, cwd: item[0], dest: item[1], src: item[2]}
      test: files:
        for item in copyTestFiles then {expand: true, dot: true, cwd: item[0], dest: item[1], src: item[2]}

    coffee:
        options: {sourceRoot: '', bare: true} # sourceMap: true
        dev: files: for folder in coffeeFolders
            {expand: true, cwd: 'src', src: folder+'*.coffee', dest:'dev', ext:'.js'}
    compass:
      dev: options: {sassDir: 'src/styles/sass', cssDir: 'dev/public/css',\
        environment: 'development', config: 'compass-config.rb'}

    mochaTest: # server side
      all:
        options: reporter: 'dot'
        src: ['dev/test/mocha-server/**/test*.js']
    karma:
      auto: {configFile: 'dev/test/karma-conf', autoWatch: true, singleRun: false}
      once: {configFile: 'dev/test/karma-conf', autoWatch: false, singleRun: true}

    concurrent:
      options: logConcurrentOutput: true
      dev: tasks: ['shell:runapp', 'look:dev']
      unit: tasks: ['mocha', 'karma:auto']

  watchConfig =
    dev:
      options:{spawn: false, debounceDelay: 100}
      copy:
        files: ['public/**', 'src/server/views/**/*.jade', 'src/**/*.json', 'src/styles/{,*/}*.css']
        tasks: ['copy:dev']
      jade:
        files: ['src/views/**/*.jade', 'src/test/**/*.jade']
        tasks: ['jade:dev']
      compass: {files: ['src/styles/sass/**'], tasks: ['compass:dev']}
      coffee:{files: coffeePatterns, tasks: ['coffee:dev']}
      runapp:
        options: {livereload: 1337, debounceDelay: 500}
        files: ['src/client/**/*.coffee', 'src/server/**/*.coffee', 'src/modules/*.coffee',
                'src/styles/sass/*.scss', 'src/server/views/**/*.jade'
        ]
        taskes: ['shell:runapp']

    mocha: # watch mochaTest
      options:{spawn: true}
      mochaTest:
        files: ['dev/modules/**/*.js', 'dev/server/**/*.js', 'dev/test/mocha-server/*.js', 'dev/test/*.js']
        tasks: ['mochaTest']

  grunt.option 'force', true
  for task in ['grunt-contrib-clean',  'grunt-contrib-copy', 'grunt-shell',
      'grunt-contrib-coffee', 'grunt-contrib-compass', 'grunt-mocha-test', 'grunt-karma',
      'grunt-contrib-watch', 'grunt-concurrent']
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

  grunt.registerTask 'compiletpl', 'compile transform function from templates', ->
    {TemplateParser, FieldTemplateListParser} = require './dev/modules/transform/transformparser'
    tplFiles = grunt.file.expand('src/modules/transform/textualizer/*.tpl')
    for file in tplFiles then do (file=file) ->
      length = file.length
      i = length-1
      while i>=0
        if file[i]=='/' then break
        i--
      fileName = file.slice(i+1, length-4)
      path = file.slice(3, i+1)
      # console.log file+' @ '+fileName+' & '+path
      moduleHead =
        """var exports, module, require, _ref;

        if (typeof window === 'object') {
        _ref = twoside('/modules/transform/textualizer/twosideModuleName'), require = _ref.require, exports = _ref.exports, module = _ref.module;
        }

        (function(require, exports, module) {
        exports.makeActions = function(t){ return"""
      moduleHead = moduleHead.replace('twosideModuleName', fileName)
      # console.log moduleHead
      moduleTail =
        """\n
        ;}
        })(require, exports, module);
        """
      templates = grunt.file.read(file, {encoding:'utf-8'})
      parser = new FieldTemplateListParser
      parse = (text) -> parser.parse(text)
      dict = parser.parse(templates)
      objFile = 'dev'+path+fileName+'.js'
      grunt.file.write(objFile, moduleHead+dict+moduleTail, {encoding:'utf-8'})

  grunt.registerTask('builddev', ['clean:dev', 'coffee:dev', 'compiletpl', 'compass', 'copy:dev'])  # builddev have include all tasks related to tests
  grunt.registerTask('build', ['builddev'])
  grunt.registerTask('dev', ['builddev', 'concurrent:dev'])
  grunt.registerTask('site', ['concurrent:dev'])
  grunt.registerTask('karm1', ['karma:once'])
  grunt.registerTask('karm', ['karma:auto'])
  grunt.registerTask('mocha1', ['mochaTest'])
  grunt.registerTask('mocha', ['mochaTest', 'look:mocha'])
  grunt.registerTask('e2e', ['shell:protractor'])
  grunt.registerTask('once', ['mochaTest', 'karma:once', 'shell:protractor'])
  grunt.registerTask('unit1', ['mochaTest', 'karma:once'])
  grunt.registerTask('unit', ['concurrent:unit'])
  grunt.registerTask('test', ['shell:protractor', 'unit'])
  grunt.registerTask('default', ['dev'])