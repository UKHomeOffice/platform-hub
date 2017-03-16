export const AuthCardComponent = {
  template: require('./auth-card.html'),
  controller: AuthCardController
};

function AuthCardController($scope, $state, authService, events) {
  'ngInject';

  const ctrl = this;

  ctrl.authData = {};

  ctrl.isAuthenticated = isAuthenticated;
  ctrl.login = login;
  ctrl.logout = logout;

  init();

  function init() {
    ctrl.authData = authService.getPayload();

    // Listen for further changes
    $scope.$on(events.auth.updated, (event, authData) => {
      ctrl.authData = authData;
    });
  }

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function login() {
    authService.authenticate();
  }

  function logout() {
    authService
      .logout()
      .then(() => {
        $state.go('home');
      });
  }
}
