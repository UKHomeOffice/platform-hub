/* eslint camelcase: 0 */

export const AnnouncementsEditorFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./announcements-editor-form.html'),
  controller: AnnouncementsEditorFormController
};

function AnnouncementsEditorFormController($state, $q, AnnouncementTemplates, Announcements, hubApiService, announcementTemplatePreviewPopupService, chipsHelpers, moment, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;
  const templateId = ctrl.transition && ctrl.transition.params().templateId;

  ctrl.AnnouncementTemplates = AnnouncementTemplates;

  ctrl.levels = Announcements.levels;
  ctrl.colours = Announcements.coloursForLevel;

  ctrl.separatorKeys = chipsHelpers.separatorKeys;
  ctrl.separatorKeysHelpText = chipsHelpers.separatorKeysHelpText;

  ctrl.ready = false;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.selectedTemplate = null;
  ctrl.contactLists = null;
  ctrl.announcement = null;

  ctrl.templateSelectChange = templateSelectChange;
  ctrl.preview = preview;
  ctrl.createOrUpdate = createOrUpdate;
  ctrl.processSlackChannelsChip = processSlackChannelsChip;

  init();

  function init() {
    ctrl.isNew = !id;

    loadInitial()
      .then(() => {
        if (ctrl.isNew) {
          ctrl.announcement = initEmptyAnnouncement();
          if (ctrl.announcement.original_template_id) {
            ctrl.selectedTemplate = AnnouncementTemplates.lookup(ctrl.announcement.original_template_id);
          }
          ctrl.loading = false;
        } else {
          loadAnnouncement();
        }
      });
  }

  function loadInitial() {
    ctrl.ready = false;
    ctrl.contactLists = null;

    return $q.all({
      templates: AnnouncementTemplates.refresh(),
      contactLists: hubApiService.getContactLists()
    }).then(results => {
      ctrl.contactLists = results.contactLists;
      ctrl.ready = true;
    });
  }

  function initEmptyAnnouncement() {
    return {
      level: ctrl.levels[0],
      original_template_id: templateId || undefined,  // `templateId` will be an empty string if none is provided in the state params
      is_global: true,
      is_sticky: false,
      publish_at: moment().add(1, 'day').format(),
      deliver_to: {
        hub_users: undefined,
        contact_lists: [],
        slack_channels: []
      }
    };
  }

  function loadAnnouncement() {
    ctrl.loading = true;
    ctrl.announcement = null;
    ctrl.selectedTemplate = null;

    hubApiService
      .getAnnouncement(id)
      .then(announcement => {
        ctrl.announcement = announcement;

        if (ctrl.announcement.original_template_id) {
          ctrl.selectedTemplate = AnnouncementTemplates.lookup(ctrl.announcement.original_template_id);
        }
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function templateSelectChange() {
    if (ctrl.announcement.original_template_id) {
      ctrl.selectedTemplate = AnnouncementTemplates.lookup(ctrl.announcement.original_template_id);
      ctrl.announcement.template_data = {};
      ctrl.announcement.title = null;
      ctrl.announcement.text = null;
    } else {
      ctrl.selectedTemplate = null;
      ctrl.announcement.template_data = null;
    }
  }

  function preview(targetEvent) {
    announcementTemplatePreviewPopupService.openWithData(
      ctrl.announcement.template_data,
      ctrl.selectedTemplate.spec.templates,
      targetEvent
    );
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

  function processSlackChannelsChip(chip) {
    if (chipsHelpers.hasInvalidChars(chip)) {
      logger.warning(`Cannot add Slack channel. ${chipsHelpers.hasInvalidCharsErrorMessage}`);
      return null;
    }
    if (!chip.startsWith('#')) {
      return '#' + chip;
    }
  }

  function validate() {
    return [];
  }
}
