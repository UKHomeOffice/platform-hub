export const HomeComponent = {
  template: require('./home.html'),
  controller: HomeController
};

function HomeController(authService) {
  'ngInject';

  const ctrl = this;

  ctrl.login = login;

  function login() {
    authService.authenticate();
  }
}
