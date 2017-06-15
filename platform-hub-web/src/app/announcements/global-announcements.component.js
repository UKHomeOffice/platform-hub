export const GlobalAnnouncementsComponent = {
  template: require('./global-announcements.html'),
  controller: GlobalAnnouncementsController
};

function GlobalAnnouncementsController(Announcements, Me, icons) {
  'ngInject';

  const ctrl = this;

  ctrl.Announcements = Announcements;
  ctrl.announcementIcon = icons.announcements;
  ctrl.markAllReadIcon = icons.markAllRead;

  ctrl.loading = true;

  ctrl.markAllRead = markAllRead;

  init();

  function init() {
    Announcements
      .refreshGlobal()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function markAllRead() {
    ctrl.loading = true;

    Me
      .globalAnnouncementsMarkAllRead()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
