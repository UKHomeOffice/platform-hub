export const AnnouncementTemplatesListComponent = {
  template: require('./announcement-templates-list.html'),
  controller: AnnouncementTemplatesListController
};

function AnnouncementTemplatesListController(hubApiService) {
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
      .getAnnouncementTemplates()
      .then(templates => {
        ctrl.templates = templates;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
