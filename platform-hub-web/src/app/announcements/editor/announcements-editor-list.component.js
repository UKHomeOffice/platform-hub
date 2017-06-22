/* eslint camelcase: 0 */

export const AnnouncementsEditorListComponent = {
  template: require('./announcements-editor-list.html'),
  controller: AnnouncementsEditorListController
};

function AnnouncementsEditorListController($mdDialog, icons, Announcements, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.Announcements = Announcements;
  ctrl.isEditable = Announcements.isEditable;
  ctrl.announcementIcon = icons.announcements;

  ctrl.loading = true;
  ctrl.saving = false;

  ctrl.publish = publish;
  ctrl.markSticky = markSticky;
  ctrl.unmarkSticky = unmarkSticky;
  ctrl.deleteAnnouncement = deleteAnnouncement;

  init();

  function init() {
    refreshAllAnnouncements();
  }

  function refreshAllAnnouncements() {
    ctrl.loading = true;

    Announcements
      .refreshAll()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function publish(announcement, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will publish the announcement, triggering any deliveries specified, and preventing any further edits to this announcement.')
      .ariaLabel('Confirm publishing of announcement')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.saving = true;

        Announcements
          .publishNow(announcement)
          .then(() => {
            logger.success('Announcement published');
          })
          .finally(() => {
            ctrl.saving = false;
          });
      });
  }

  function markSticky(announcement) {
    ctrl.saving = true;

    Announcements
      .markSticky(announcement)
      .then(() => {
        logger.success('Marked announcement as sticky');
        announcement.is_sticky = true;
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function unmarkSticky(announcement) {
    ctrl.saving = true;

    Announcements
      .unmarkSticky(announcement)
      .then(() => {
        logger.success('Unmarked announcement as sticky');
        announcement.is_sticky = false;
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function deleteAnnouncement(announcement, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the announcement permanently from the hub.')
      .ariaLabel('Confirm deletion of announcement')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.saving = true;

        Announcements
          .deleteAnnouncement(announcement)
          .then(() => {
            logger.success('Announcement deleted');
            refreshAllAnnouncements();
          })
          .finally(() => {
            ctrl.saving = false;
          });
      });
  }
}
