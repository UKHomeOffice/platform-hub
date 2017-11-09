export const projectServiceSelectorPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.openForProjectOnly = function targetEvent() {
    return _open('project-only', targetEvent);
  };

  service.openForServiceOnly = function (targetEvent) {
    return _open('service-only', targetEvent);
  };

  service.openForProjectOrService = function (targetEvent) {
    return _open('project-or-service', targetEvent);
  };

  return service;

  function _open(mode, targetEvent) {
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
        mode
      }
    });
  }
};
