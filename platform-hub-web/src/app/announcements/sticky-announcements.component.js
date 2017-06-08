export const StickyAnnouncementsComponent = {
  template: require('./sticky-announcements.html'),
  controller: StickyAnnouncementsController
};

function StickyAnnouncementsController($scope, Announcements, icons) {
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
