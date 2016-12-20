/* eslint angular/log: 0 */

// Important instructions for karma-webpack – tells it builds a single bundle
// to run all tests from.
const context = require.context('./app', true, /\.(js|ts|tsx)$/);
context.keys().forEach(path => {
  try {
    context(path);
  } catch (err) {
    console.error('ERROR - file: ', path);
    console.error(err);
  }
});
