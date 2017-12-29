export const kubernetesIdentityTokensPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(identity, targetEvent) {
    return $mdDialog.show({
      template: require('./kubernetes-identity-tokens-popup.html'),
      controller: 'KubernetesIdentityTokensPopupController',
      controllerAs: '$ctrl',
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      locals: {
        identity
      }
    });
  }
};
