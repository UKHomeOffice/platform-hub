/* eslint camelcase: 0 */

export const AnnouncementTemplatesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./announcement-templates-form.html'),
  controller: AnnouncementTemplatesFormController
};

function AnnouncementTemplatesFormController($state, hubApiService, formFieldsValidator, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

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
      spec: {
        fields: [],
        templates: {}
      }
    };
  }

  function loadFormFieldTypes() {
    ctrl.ready = false;
    ctrl.formFieldTypes = null;

    hubApiService
      .getAnnouncementTemplateFormFieldTypes()
      .then(types => {
        ctrl.formFieldTypes = types;
        ctrl.ready = true;
      });
  }

  function loadTemplate() {
    ctrl.loading = true;
    ctrl.template = null;

    hubApiService
      .getAnnouncementTemplate(id)
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
        .createAnnouncementTemplate(ctrl.template)
        .then(template => {
          logger.success('New annnouncement template created');
          $state.go('announcements.templates.detail', {id: template.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      hubApiService
        .updateAnnouncementTemplate(ctrl.template.id, ctrl.template)
        .then(template => {
          logger.success('Announcement template updated');
          $state.go('announcements.templates.detail', {id: template.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function validate(template) {
    return formFieldsValidator.validate(template.spec.fields);
  }
}
