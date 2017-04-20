export const AuthCardComponent = {
  template: require('./auth-card.html'),
  controller: AuthCardController
};

function AuthCardController($scope, $state, authService, onboardingTrigger, Me) {
  'ngInject';

  const ctrl = this;

  ctrl.Me = Me;

  ctrl.isAuthenticated = isAuthenticated;
  ctrl.login = login;
  ctrl.logout = logout;

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function login() {
    authService
      .authenticate()
      .then(onboardingTrigger);
  }

  function logout() {
    authService
      .logout()
      .then(() => {
        $state.go('home');
      });
  }
}
