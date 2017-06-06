/* eslint no-useless-escape: 0 */

export const SimpleFormatFilter = function ($filter) {
  'ngInject';

  // Based on: https://github.com/RStankov/angular-simple-format

  const linky = $filter('linky');

  return function (text) {
    return linky(String(text || '')).replace(/\&#10;/g, '&#10;<br>');
  };
};
