const webpack = require('webpack');

const autoprefixer = require('autoprefixer');

const bourbonIncludePaths = require('bourbon').includePaths;

module.exports = {
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: 'eslint-loader',
        enforce: 'pre'
      },
      {
        test: /\.(css|scss)$/,
        use: [
          'style-loader',
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              includePaths: bourbonIncludePaths
            }
          },
          {
            loader: 'postcss-loader',
            options: {
              plugins: function () {  // eslint-disable-line object-shorthand
                return [
                  autoprefixer
                ];
              }
            }
          }
        ]
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: [
          'ng-annotate-loader',
          'babel-loader'
        ]
      },
      {
        test: /\.html$/,
        use: 'html-loader'
      }
    ]
  },
  plugins: [
    new webpack.LoaderOptionsPlugin({
      options: {},
      debug: true
    })
  ],
  devtool: 'source-map'
};
