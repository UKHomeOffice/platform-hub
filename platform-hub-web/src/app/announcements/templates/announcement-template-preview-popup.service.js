export const announcementTemplatePreviewPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = function (fields, templates, targetEvent) {
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
      locals: {
        fields,
        templates
      }
    });
  };

  return service;
};
