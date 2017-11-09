export const kubernetesTokenEscalatePrivilegePopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(tokenId, targetEvent) {
    return $mdDialog.show({
      template: require('./kubernetes-token-escalate-privilege-popup.html'),
      controller: 'KubernetesTokenEscalatePrivilegePopupController',
      controllerAs: '$ctrl',
      bindToController: true,
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      locals: {
        tokenId
      }
    });
  }
};
