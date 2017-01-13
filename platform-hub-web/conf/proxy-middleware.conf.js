const proxy = require('http-proxy-middleware');

module.exports = proxy(
  '/api',
  {
    target: 'http://localhost:8080',
    changeOrigin: true,
    ws: true,
    pathRewrite: {
      '^/api': ''
    },
    logLevel: 'debug'
  }
);
