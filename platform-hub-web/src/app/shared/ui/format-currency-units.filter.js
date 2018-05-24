export const FormatCurrencyUnitsFilter = function ($filter) {
  'ngInject';

  const currencyFilter = $filter('currency');

  return function (value, symbol) {
    return currencyFilter((value / 100).toFixed(2), symbol);
  };
};
