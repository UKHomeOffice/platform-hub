export const HomeComponent = {
  template: require('./home.html'),
  controller: HomeController
};

function HomeController($scope, events, authService, onboardingTrigger, AppSettings, PlatformThemesList) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.PlatformThemesList = PlatformThemesList;

  ctrl.login = login;
  ctrl.isAuthenticated = isAuthenticated;

  init();

  function init() {
    // Listen for changes to the Me profile data
    $scope.$on(events.auth.updated, () => {
      if (isAuthenticated()) {
        refresh();
      }
    });

    if (isAuthenticated()) {
      refresh();
    }
  }

  function refresh() {
    PlatformThemesList.refresh();
  }

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function login() {
    authService
      .authenticate()
      .then(onboardingTrigger);
  }
}
