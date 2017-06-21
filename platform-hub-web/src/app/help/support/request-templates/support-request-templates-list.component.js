export const SupportRequestTemplatesListComponent = {
  template: require('./support-request-templates-list.html'),
  controller: SupportRequestTemplatesListController
};

function SupportRequestTemplatesListController(hubApiService) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = false;
  ctrl.templates = [];

  init();

  function init() {
    loadTemplates();
  }

  function loadTemplates() {
    ctrl.loading = true;
    ctrl.templates = [];

    hubApiService
      .getSupportRequestTemplates()
      .then(templates => {
        ctrl.templates = templates;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
