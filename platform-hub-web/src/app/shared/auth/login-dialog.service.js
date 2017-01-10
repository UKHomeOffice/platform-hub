export const loginDialogService = function ($document, $mdDialog) {
  'ngInject';

  return function (targetEvent) {
    return $mdDialog.show({
      template: require('./login-dialog.html'),
      controller: 'LoginDialogController',
      controllerAs: '$ctrl',
      bindToController: true,
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line babel/object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      fullscreen: true
    });
  };
};
