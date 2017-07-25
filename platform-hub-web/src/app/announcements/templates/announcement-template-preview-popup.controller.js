export const AnnouncementTemplatePreviewPopupController = function ($mdDialog, fields, data, templates, results, hubApiService) {
  'ngInject';

  const ctrl = this;

  ctrl.processing = false;
  ctrl.readOnly = false;
  ctrl.fields = fields;
  ctrl.data = {};
  ctrl.results = null;

  ctrl.finish = $mdDialog.hide;
  ctrl.preview = preview;

  init();

  function init() {
    if (results) {
      ctrl.readOnly = true;
      ctrl.results = results;
    } else if (data) {
      ctrl.readOnly = true;
      ctrl.data = data;
      preview();
    } else {
      ctrl.readOnly = false;
    }
  }

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
