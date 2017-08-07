/* eslint camelcase: 0 */

export const AnnouncementsEditorListComponent = {
  template: require('./announcements-editor-list.html'),
  controller: AnnouncementsEditorListController
};

function AnnouncementsEditorListController($q, $mdDialog, icons, AnnouncementTemplates, Announcements, announcementTemplatePreviewPopupService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.AnnouncementTemplates = AnnouncementTemplates;
  ctrl.Announcements = Announcements;
  ctrl.isEditable = Announcements.isEditable;
  ctrl.announcementIcon = icons.announcements;

  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.templates = {};

  ctrl.preview = preview;
  ctrl.publish = publish;
  ctrl.markSticky = markSticky;
  ctrl.unmarkSticky = unmarkSticky;
  ctrl.resend = resend;
  ctrl.deleteAnnouncement = deleteAnnouncement;

  init();

  function init() {
    reload();
  }

  function reload() {
    ctrl.loading = true;

    $q.all([
      AnnouncementTemplates.refresh(),
      Announcements.refreshAll()
    ]).finally(() => {
      ctrl.loading = false;
    });
  }

  function preview(announcement, targetEvent) {
    announcementTemplatePreviewPopupService.openWithResults(
      announcement.preview,
      targetEvent
    );
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
        ctrl.processing = true;

        Announcements
          .publishNow(announcement)
          .then(() => {
            logger.success('Announcement published');
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }

  function markSticky(announcement) {
    ctrl.processing = true;

    Announcements
      .markSticky(announcement)
      .then(() => {
        logger.success('Marked announcement as sticky');
        announcement.is_sticky = true;
      })
      .finally(() => {
        ctrl.processing = false;
      });
  }

  function unmarkSticky(announcement) {
    ctrl.processing = true;

    Announcements
      .unmarkSticky(announcement)
      .then(() => {
        logger.success('Unmarked announcement as sticky');
        announcement.is_sticky = false;
      })
      .finally(() => {
        ctrl.processing = false;
      });
  }

  function resend(announcement, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will mark the announcement for resending, which will send out new reminder messages to the specified delivery targets.')
      .ariaLabel('Confirm resending of announcement')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        Announcements
          .resend(announcement)
          .then(() => {
            logger.success('Announcement has been marked for resending – it will be sent out soon');
            reload();
          })
          .finally(() => {
            ctrl.processing = false;
          });
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
        ctrl.processing = true;

        Announcements
          .deleteAnnouncement(announcement)
          .then(() => {
            logger.success('Announcement deleted');
            reload();
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }
}
