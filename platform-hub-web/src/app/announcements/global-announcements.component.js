export const GlobalAnnouncementsComponent = {
  template: require('./global-announcements.html'),
  controller: GlobalAnnouncementsController
};

function GlobalAnnouncementsController(Announcements, icons) {
  'ngInject';

  const ctrl = this;

  ctrl.Announcements = Announcements;
  ctrl.announcementIcon = icons.announcements;

  ctrl.loading = true;

  init();

  function init() {
    Announcements
      .refreshGlobal()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
