module.exports = (config) ->
  config.set
    basePath: '..'   # @hopen/dev
# It doesnot work. module(should be property of window) or angular.mock.module throw error!!!
# but failed with browserify, and protractor does not yet support mocha at the moment. sadly.
#    frameworks: ['mocha']   #, 'chai', 'chai-as-promised'
    frameworks: ['jasmine']
    reporters:['dots', 'html']
    htmlReporter:
      outputDir: 'dist/test/karma/html',
      templatePath: 'src/test/jasmine-template.html'
    files: [
      '../public/js/lodash.js'
      '../public/js/jquery.js'

#      '../public/ace/ace.js'
#      '../public/superfish/dist/js/superfish.js'
#      '../public/angular/angular.js'
#      '../public/angular/angular-resource.js'
#      '../public/angular/angular-mocks.js'
#      '../public/js/ui-bootstrap-custom-tpls-0.7.0.js'
#      '../public/ace/ui-ace.js'
#
#      'modules/twoside.js'
#      'modules/peasy.js'
#      'modules/library.js'
#      'modules/abstract/common.js'
#      'modules/display/base.js'
#       'modules/display/common.js'
#      'modules/display/english.js'
#      'modules/display/chinese.js'
#      'modules/display/highlanguage.js'
#      'modules/display/js.js'
#      'modules/dom/common.js'
#      'modules/transform/abstract2display/abstract2display.js'
#      'modules/transform/display2abstract.js'
#      'modules/transform/display2dom.js'
#      'modules/transform/transformparser.js'
#      'modules/transform/textualizer/textualizer.js'
#      'modules/transform/textualizer/cstylegenerator.js'
#      'modules/transform/textualizer/cgenerator.js'
#      'modules/transform/textualizer/jstemplate.js'
#      'modules/transform/textualizer/jsgenerator.js'
#      'modules/transform/textualizer/pygenerator.js'
#      'modules/file.js'
#      'modules/componentstreedata.js'
#      'modules/projectfilesdata.js'
#
#      'client/app.js'
#
#      'client/controllers/appctrl.js'
#      'client/controllers/commandctrl.js'
#      'client/controllers/filetabctrl.js'
#
#      'client/directives/splitter.js'
#      'client/directives/treeview.js'
#      'client/directives/programfile.js'
#      'client/directives/program.js'
#      'client/directives/blink.js'
#
#      'test/karma/modules/testpeasy.js'
##      'test/karma/modules/abstract/testcommon.js'
#      'test/karma/modules/display/testcommon.js'
#      'test/karma/modules/display/testchinese.js'
#      'test/karma/modules/transform/testabstract2display.js'
#      'test/karma/modules/transform/testdisplay2abstract.js'
#      'test/karma/modules/transform/testdisplay2dom.js'
##      'test/karma/modules/transform/testjsgenerator.js'
#      'test/karma/controllers/testappctrl.js'
#      'test/karma/controllers/testcommandctrl.js'
#      'test/karma/controllers/testfiletabctrl.js'
    ]
    exclude: []
    #after switching from win7 64bit to win7 32bit, dsable many services, karma say chrome have not captured in 6000ms. use 9876 ok.
    #https://github.com/karma-runner/karma/issues/635
    port: 9876 #8080
    # level of logging
    # possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel: config.LOG_INFO
#    autoWatch: true
    # - Chrome, ChromeCanary, Firefox, Opera, Safari (only Mac), PhantomJS, IE (only Windows)
    browsers: ['Chrome']
#    singleRun: false

