/* eslint camelcase: 0 */

export const SupportRequestTemplatesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./support-request-templates-form.html'),
  controller: SupportRequestTemplatesFormController
};

function SupportRequestTemplatesFormController($state, hubApiService, UserScopes, formFieldsValidator, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.userScopes = UserScopes.all;

  ctrl.ready = false;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.formFieldTypes = null;
  ctrl.template = null;

  ctrl.createOrUpdate = createOrUpdate;

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

  function validate(template) {
    return formFieldsValidator.validate(template.form_spec.fields);
  }
}
