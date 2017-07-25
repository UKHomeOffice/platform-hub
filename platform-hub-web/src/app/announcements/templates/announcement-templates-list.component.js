export const AnnouncementTemplatesListComponent = {
  template: require('./announcement-templates-list.html'),
  controller: AnnouncementTemplatesListController
};

function AnnouncementTemplatesListController(AnnouncementTemplates) {
  'ngInject';

  const ctrl = this;

  ctrl.AnnouncementTemplates = AnnouncementTemplates;

  ctrl.loading = false;

  init();

  function init() {
    ctrl.loading = true;

    AnnouncementTemplates
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
