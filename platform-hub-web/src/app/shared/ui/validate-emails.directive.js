export const validateEmails = function () {
  'ngInject';

  // Expected to be used with `ng-list` so that the model is an Array

  // Copied from https://github.com/angular/angular.js/blob/master/src/ng/directive/input.js
  const EMAIL_REGEXP = /^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$/;

  return {
    restrict: 'A',
    require: 'ngModel',
    link(scope, elem, attr, ngModel) {
      ngModel.$validators.validateEmails = function (modelValue, viewValue) {
        let values = modelValue || viewValue;

        if (ngModel.$isEmpty(values)) {
          values = [];
        }
        if (!angular.isArray(values)) {
          throw new Error('validate-emails expects model to be an array.');
        }

        return values.every(i => {
          return EMAIL_REGEXP.test(i);
        });
      };
    }
  };
};
