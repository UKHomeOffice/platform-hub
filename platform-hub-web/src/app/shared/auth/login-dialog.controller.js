export const LoginDialogController = function ($mdDialog, authService) {
  'ngInject';

  const ctrl = this;

  ctrl.cancel = cancel;
  ctrl.login = login;

  function cancel() {
    $mdDialog.cancel();
  }

  function login() {
    authService
      .authenticate()
      .then($mdDialog.hide)
      .catch(ctrl.cancel);
  }
};
