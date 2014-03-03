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

