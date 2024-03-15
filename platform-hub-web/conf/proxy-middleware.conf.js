const proxy = require('http-proxy-middleware');

module.exports = proxy(
  '/api',
  {
    target: 'http://host.docker.internal:8080',
    changeOrigin: true,
    ws: true,
    pathRewrite: {
      '^/api': ''
    },
    logLevel: 'debug'
  }
);
