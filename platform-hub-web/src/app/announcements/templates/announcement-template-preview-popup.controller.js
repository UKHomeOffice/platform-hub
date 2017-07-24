export const AnnouncementTemplatePreviewPopupController = function ($mdDialog, fields, templates, hubApiService) {
  'ngInject';

  const ctrl = this;

  ctrl.processing = false;
  ctrl.fields = fields;
  ctrl.data = {};
  ctrl.results = null;

  ctrl.finish = $mdDialog.hide;
  ctrl.preview = preview;

  function preview() {
    ctrl.processing = true;
    ctrl.results = null;

    hubApiService
      .previewAnnouncementTemplate(templates, ctrl.data)
      .then(results => {
        ctrl.results = results;
      })
      .finally(() => {
        ctrl.processing = false;
      });
  }
};
