export const kubeConfigHelperPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(kubeId, token, targetEvent) {
    return $mdDialog.show({
      template: require('./kube-config-helper-popup.html'),
      controller: 'KubeConfigHelperPopupController',
      controllerAs: '$ctrl',
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      locals: {
        kubeId,
        token
      }
    });
  }
};
