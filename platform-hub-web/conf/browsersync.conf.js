const conf = require('./gulp.conf');
const proxyMiddleware = require('./proxy-middleware.conf');

module.exports = function () {
  return {
    server: {
      baseDir: [
        conf.paths.tmp,
        conf.paths.src
      ],
      middleware: proxyMiddleware
    },
    open: false
  };
};
