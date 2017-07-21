export const AnnouncementTemplatesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./announcement-templates-detail.html'),
  controller: AnnouncementTemplatesDetailController
};

function AnnouncementTemplatesDetailController($mdDialog, $state, hubApiService, announcementTemplatePreviewPopupService, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.template = null;

  ctrl.deleteTemplate = deleteTemplate;
  ctrl.triggerPreview = triggerPreview;

  init();

  function init() {
    loadTemplate();
  }

  function loadTemplate() {
    ctrl.loading = true;
    ctrl.template = null;

    hubApiService
      .getAnnouncementTemplate(id)
      .then(template => {
        ctrl.template = template;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteTemplate(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the announcement template permanently from the hub.')
      .ariaLabel('Confirm deletion of announcement template')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .deleteAnnouncementTemplate(ctrl.template.id)
          .then(() => {
            logger.success('Announcement template deleted');
            $state.go('announcements.templates.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }

  function triggerPreview(targetEvent) {
    announcementTemplatePreviewPopupService.open(
      ctrl.template.spec.fields,
      ctrl.template.spec.templates,
      targetEvent
    );
  }
}
