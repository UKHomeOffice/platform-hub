export const chipsHelpers = function ($mdConstant, _) {
  'ngInject';

  const semicolon = 186;
  const separatorKeys = [
    $mdConstant.KEY_CODE.ENTER,
    $mdConstant.KEY_CODE.COMMA,
    semicolon
  ];

  const separatorKeysHelpText = 'Make sure to press <Enter> or , or ; to add an entry to the list';

  const hasInvalidChars = function (chip) {
    return _.includes(chip, ',') || _.includes(chip, ';');
  };

  const hasInvalidCharsErrorMessage = 'Contains invalid characters (\',\' and \';\' are not allowed).';

  return {
    separatorKeys,
    separatorKeysHelpText,
    hasInvalidChars,
    hasInvalidCharsErrorMessage
  };
};
