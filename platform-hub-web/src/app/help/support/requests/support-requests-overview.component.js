export const SupportRequestsOverviewComponent = {
  template: require('./support-requests-overview.html'),
  controller: SupportRequestsOverviewController
};

function SupportRequestsOverviewController(hubApiService) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = this;
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
