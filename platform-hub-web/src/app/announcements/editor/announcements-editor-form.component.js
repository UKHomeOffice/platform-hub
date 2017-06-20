/* eslint camelcase: 0 */

export const AnnouncementsEditorFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./announcements-editor-form.html'),
  controller: AnnouncementsEditorFormController
};

function AnnouncementsEditorFormController($state, $mdConstant, Announcements, ContactLists, hubApiService, moment, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.levels = Announcements.levels;
  ctrl.colours = Announcements.coloursForLevel;
  ctrl.contactLists = ContactLists.listIds;

  const semicolon = 186;
  ctrl.customKeys = [
    $mdConstant.KEY_CODE.ENTER,
    $mdConstant.KEY_CODE.COMMA,
    semicolon
  ];

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.announcement = null;

  ctrl.createOrUpdate = createOrUpdate;
  ctrl.processSlackChannelName = processSlackChannelName;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.announcement = initEmptyAnnouncement();
      ctrl.loading = false;
    } else {
      loadAnnouncement();
    }
  }

  function initEmptyAnnouncement() {
    return {
      level: ctrl.levels[0],
      is_global: true,
      is_sticky: false,
      publish_at: moment().add(1, 'day').format(),
      deliver_to: {
        hub_users: undefined,
        contact_lists: undefined,
        slack_channels: []
      }
    };
  }

  function loadAnnouncement() {
    ctrl.loading = true;
    ctrl.announcement = null;

    hubApiService
      .getAnnouncement(id)
      .then(announcement => {
        ctrl.announcement = announcement;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.announcementForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    const errors = validate(ctrl.announcement);
    if (errors.length > 0) {
      logger.error(errors.join('<br />'));
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      Announcements
        .createAnnouncement(ctrl.announcement)
        .then(() => {
          logger.success('Announcement created');
          $state.go('announcements.editor.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      Announcements
        .updateAnnouncement(ctrl.announcement.id, ctrl.announcement)
        .then(() => {
          logger.success('Announcement updated');
          $state.go('announcements.editor.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function processSlackChannelName(chip) {
    if (!chip.startsWith('#')) {
      return '#' + chip;
    }
  }

  function validate() {
    return [];
  }
}
