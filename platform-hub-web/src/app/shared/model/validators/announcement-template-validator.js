export const announcementTemplateValidator = function (formFieldsValidator, _) {
  'ngInject';

  const TEMPLATE_DEFINITION_KEYS = [
    'title',
    'on_hub',
    'email_html',
    'email_text',
    'slack'
  ];

  const service = {};

  service.validate = function (template) {
    return _.concat(
      formFieldsValidator.validate(template.spec.fields),
      validateTemplateDefinitions(template.spec.templates, template.spec.fields)
    );
  };

  return service;

  function validateTemplateDefinitions(templates, fields) {
    const fieldIds = _.map(fields, 'id');

    const errors = [];

    // Make sure the fields used in the template definitions actually correspond
    // to fields that are defined.

    TEMPLATE_DEFINITION_KEYS.forEach(d => {
      const unused = findUnusedFieldsInTemplateDefinition(templates[d], fieldIds);
      if (unused.length > 0) {
        errors.push(`${d} template definition references field(s) that don't exist: ${unused.join(', ')}`);
      }
    });

    return errors;
  }

  function findUnusedFieldsInTemplateDefinition(definition, allowedFieldIds) {
    const regex = /{{(\w+?)}}/gm;
    let matches = null;
    const foundIds = [];
    while ((matches = regex.exec(definition)) !== null) {
      foundIds.push(matches[1]);
    }
    return _.difference(foundIds, allowedFieldIds);
  }
};
