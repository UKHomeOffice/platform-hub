/* eslint camelcase: 0 */

export const SupportRequestTemplatesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./support-request-templates-form.html'),
  controller: SupportRequestTemplatesFormController
};

function SupportRequestTemplatesFormController($q, $state, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.fieldIdRegex = '\\w+';

  ctrl.ready = false;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.formFieldTypes = null;
  ctrl.template = null;

  ctrl.createOrUpdate = createOrUpdate;
  ctrl.addFormField = addFormField;
  ctrl.removeFormField = removeFormField;
  ctrl.moveFieldDown = moveFieldDown;
  ctrl.moveFieldUp = moveFieldUp;

  init();

  function init() {
    ctrl.isNew = !id;

    loadFormFieldTypes();

    if (ctrl.isNew) {
      ctrl.template = initEmptyTemplate();
      ctrl.loading = false;
    } else {
      loadTemplate();
    }
  }

  function initEmptyTemplate() {
    return {
      form_spec: {
        fields: []
      }
    };
  }

  function loadFormFieldTypes() {
    ctrl.ready = false;
    ctrl.formFieldTypes = null;

    hubApiService
      .getSupportRequestTemplateFormFieldTypes()
      .then(types => {
        ctrl.formFieldTypes = types;
        ctrl.ready = true;
      });
  }

  function loadTemplate() {
    ctrl.loading = true;
    ctrl.template = null;

    hubApiService
      .getSupportRequestTemplate(id)
      .then(template => {
        ctrl.template = template;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.templateForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    const errors = validate(ctrl.template);
    if (errors.length > 0) {
      logger.error(errors.join('<br />'));
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      hubApiService
        .createSupportRequestTemplate(ctrl.template)
        .then(template => {
          logger.success('New support request template created');
          $state.go('help.support.request-templates.detail', {id: template.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      hubApiService
        .updateSupportRequestTemplate(ctrl.template.id, ctrl.template)
        .then(template => {
          logger.success('Support request template updated');
          $state.go('help.support.request-templates.detail', {id: template.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function addFormField() {
    if (!ctrl.template.form_spec.fields) {
      ctrl.template.form_spec.fields = [];
    }
    ctrl.template.form_spec.fields.push({
      field_type: ctrl.formFieldTypes[0],
      required: true,
      multiple: false
    });
  }

  function removeFormField(ix) {
    if (!_.isEmpty(ctrl.template.form_spec.fields)) {
      ctrl.template.form_spec.fields.splice(ix, 1);
    }
  }

  function validate(template) {
    const errors = [];

    const formFields = template.form_spec.fields;

    const uniq = _.uniq(_.map(formFields, 'id'));

    if (uniq.length !== formFields.length) {
      errors.push('Form field IDs must be unique – you\'ve used the same ID twice or more.');
    }

    return errors;
  }

  function moveFieldDown(ix) {
    const fields = ctrl.template.form_spec.fields;
    const field1 = fields[ix];
    const field2 = fields[ix + 1];
    fields.splice(ix, 2, field2, field1);
  }

  function moveFieldUp(ix) {
    const fields = ctrl.template.form_spec.fields;
    const field1 = fields[ix - 1];
    const field2 = fields[ix];
    fields.splice(ix - 1, 2, field2, field1);
  }
}
