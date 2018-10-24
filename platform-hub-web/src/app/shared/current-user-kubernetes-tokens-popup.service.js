export const currentUserKubernetesTokensPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(targetEvent) {
    return $mdDialog.show({
      template: require('./current-user-kubernetes-tokens-popup.html'),
      controller: 'currentUserKubernetesTokensPopupController',
      controllerAs: '$ctrl',
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false
    });
  }
};
