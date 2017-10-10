export const projectServiceSelectorPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(serviceIsOptional, targetEvent) {
    return $mdDialog.show({
      template: require('./project-service-selector-popup.html'),
      controller: 'ProjectServiceSelectorPopupController',
      controllerAs: '$ctrl',
      bindToController: true,
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      locals: {
        serviceIsOptional
      }
    });
  }
};
