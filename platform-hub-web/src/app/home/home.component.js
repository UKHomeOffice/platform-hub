export const HomeComponent = {
  template: require('./home.html'),
  controller: HomeController
};

function HomeController(authService) {
  'ngInject';

  const ctrl = this;

  ctrl.login = login;
  ctrl.isAuthenticated = isAuthenticated;

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function login() {
    authService.authenticate();
  }
}
