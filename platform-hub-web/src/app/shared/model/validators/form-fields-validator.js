export const formFieldsValidator = function (_) {
  'ngInject';

  const service = {};

  service.validate = function (fields) {
    const errors = [];

    if (_.isNull(fields) || _.isEmpty(fields)) {
      errors.push('No form fields have been specified. Specify at least one.');
    } else {
      const uniq = _.uniq(_.filter(_.map(fields, 'id')));

      if (uniq.length !== fields.length) {
        errors.push('Form field IDs must be unique – you\'ve used the same ID twice or more.');
      }
    }

    return errors;
  };

  return service;
};
