export const announcementTemplatePreviewPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = function (fields, templates, data, targetEvent) {
    return _open({
      fields,
      data: null,
      templates,
      results: null
    }, targetEvent);
  };

  service.openWithData = function (data, templates, targetEvent) {
    return _open({
      fields: null,
      data,
      templates,
      results: null
    }, targetEvent);
  };

  service.openWithResults = function (results, targetEvent) {
    return _open({
      fields: null,
      data: null,
      templates: null,
      results
    }, targetEvent);
  };

  return service;

  function _open(locals, targetEvent) {
    return $mdDialog.show({
      template: require('./announcement-template-preview-popup.html'),
      controller: 'AnnouncementTemplatePreviewPopupController',
      controllerAs: '$ctrl',
      bindToController: true,
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      fullscreen: true,
      locals
    });
  }
};
