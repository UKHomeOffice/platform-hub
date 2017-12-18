const conf = require('./gulp.conf');

module.exports = function (config) {
  const configuration = {
    basePath: '../',
    singleRun: true,
    autoWatch: false,
    logLevel: 'INFO',
    junitReporter: {
      outputDir: 'test-reports'
    },
    browsers: [
      'PhantomJS'
    ],
    browserNoActivityTimeout: 60000,
    frameworks: [
      'jasmine-jquery',
      'jasmine'
    ],
    files: [
      'node_modules/es6-shim/es6-shim.js',
      conf.path.src('index.spec.js'),
      conf.path.src('**/*.html')
    ],
    preprocessors: {
      [conf.path.src('index.spec.js')]: [
        'webpack'
      ],
      [conf.path.src('**/*.html')]: [
        'ng-html2js'
      ]
    },
    ngHtml2JsPreprocessor: {
      stripPrefix: `${conf.paths.src}/`,
      moduleName: 'app'
    },
    reporters: ['progress', 'coverage', 'verbose-summary'],
    coverageReporter: {
      type: 'html',
      dir: 'coverage/'
    },
    webpack: require('./webpack-test.conf'),
    webpackMiddleware: {
      noInfo: true
    },
    plugins: [
      require('karma-jasmine-jquery'),
      require('karma-jasmine'),
      require('karma-junit-reporter'),
      require('karma-coverage'),
      require('karma-verbose-summary-reporter'),
      require('karma-phantomjs-launcher'),
      require('karma-phantomjs-shim'),
      require('karma-ng-html2js-preprocessor'),
      require('karma-webpack')
    ]
  };

  config.set(configuration);
};
